#!/usr/bin/env python3
"""Static checks for THE LAST LIGHT Godot project (no Godot install needed).

Run from anywhere:  python3 tools/validate_project.py
Optional:           pip install gdtoolkit==4.3.3   (adds a full GDScript syntax parse)

Checks
  1. GDScript syntax (gdtoolkit, if installed) and tab-only indentation.
  2. Every .tscn: ext_resource files exist, ExtResource/SubResource ids are defined,
     node parents exist, load_steps is right, instanced scenes exist.
  3. Every $Node / get_node("...") / NodePath export used by a script resolves inside the
     scene the script is attached to (including nodes from instanced sub-scenes).
  4. Every input action the code uses exists in project.godot.
  5. Every res:// path in preload()/load()/change_scene_to_file() exists.
  6. Calls, properties and signals used on variables typed with one of the project's own
     classes (e.g. player.flashlight.is_on(), gm.fuses_changed.connect) exist on that class.
  7. class_name values are unique and the main scene / autoloads exist.
This catches wiring mistakes. It cannot replace opening the project in Godot and playing it.
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
errors = []
notes = []


def err(msg):
    errors.append(msg)


def res(path):
    return os.path.join(ROOT, path.replace("res://", ""))


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def project_files(ext):
    out = []
    for base, dirs, files in os.walk(ROOT):
        if os.path.exists(os.path.join(base, ".gdignore")):
            dirs[:] = []
            continue
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in files:
            if f.endswith(ext):
                out.append(os.path.join(base, f))
    return sorted(out)


# --- project.godot -----------------------------------------------------------

project = read(os.path.join(ROOT, "project.godot"))
actions = set(re.findall(r"^(\w+)=\{\s*\n\"deadzone\"", project, re.M))
main_scene = re.search(r'run/main_scene="([^"]+)"', project).group(1)
if not os.path.exists(res(main_scene)):
    err("project.godot: main scene %s is missing" % main_scene)
autoloads = dict(re.findall(r'^(\w+)="\*?(res://[^"]+)"', project.split("[autoload]")[1].split("[")[0], re.M))
for name, path in autoloads.items():
    if not os.path.exists(res(path)):
        err("autoload %s -> %s is missing" % (name, path))
for bad in re.findall(r'"physical_keycode":(_\w+)', project):
    err("project.godot: invalid keycode %s" % bad)

# --- scripts -------------------------------------------------------------------

scripts = {}  # res path -> info
for path in project_files(".gd"):
    rp = "res://" + os.path.relpath(path, ROOT).replace(os.sep, "/")
    src = read(path)
    info = {"path": path, "src": src, "class": None, "extends": None,
            "members": {}, "funcs": set(), "signals": set(), "consts": set()}
    m = re.search(r"^class_name\s+(\w+)", src, re.M)
    if m:
        info["class"] = m.group(1)
    m = re.search(r"^extends\s+(\w+)", src, re.M)
    if m:
        info["extends"] = m.group(1)
    for m in re.finditer(r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:static\s+)?var\s+(\w+)\s*(?::\s*([\w\[\]]+))?\s*(?::?=\s*(.+))?$", src, re.M):
        name, typ, init = m.group(1), m.group(2), m.group(3) or ""
        if not typ:
            cast = re.search(r"\bas\s+(\w+)\s*$", init)
            new = re.match(r"(\w+)\.new\(\)", init)
            typ = cast.group(1) if cast else (new.group(1) if new else None)
        info["members"][name] = typ
    info["funcs"] = set(re.findall(r"^(?:static\s+)?func\s+(\w+)", src, re.M))
    info["signals"] = set(re.findall(r"^signal\s+(\w+)", src, re.M))
    info["consts"] = set(re.findall(r"^const\s+(\w+)", src, re.M)) | set(re.findall(r"^enum\s+(\w+)", src, re.M))
    for line_no, line in enumerate(src.splitlines(), 1):
        if re.match(r"^ +\S", line):
            err("%s:%d indented with spaces (project uses tabs)" % (rp, line_no))
    scripts[rp] = info

classes = {}
for rp, info in scripts.items():
    if info["class"]:
        if info["class"] in classes:
            err("class_name %s defined twice" % info["class"])
        classes[info["class"]] = info
for name, path in autoloads.items():
    if path in scripts:
        classes.setdefault(name, scripts[path])

if shutil.which("gdparse"):
    for rp, info in scripts.items():
        r = subprocess.run(["gdparse", info["path"]], capture_output=True, text=True)
        if r.returncode != 0:
            err("%s: syntax error\n%s" % (rp, (r.stderr or r.stdout)[-800:]))
else:
    notes.append("gdtoolkit not installed: skipped the full syntax parse")

# --- scenes --------------------------------------------------------------------

def parse_scene(path):
    text = read(path)
    scene = {"ext": {}, "sub": set(), "nodes": [], "text": text}
    for m in re.finditer(r'^\[ext_resource ([^\]]*)\]', text, re.M):
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', m.group(1)))
        scene["ext"][attrs["id"]] = attrs
    scene["sub"] = set(re.findall(r'^\[sub_resource [^\]]*id="([^"]+)"', text, re.M))
    blocks = re.split(r"^(?=\[node )", text, flags=re.M)
    for block in blocks:
        if not block.startswith("[node "):
            continue
        header = block.split("]\n", 1)[0]
        attrs = dict(re.findall(r'(\w+)="([^"]*)"', header))
        inst = re.search(r'instance=ExtResource\("([^"]+)"\)', header)
        script = re.search(r'^script = ExtResource\("([^"]+)"\)', block, re.M)
        props = dict(re.findall(r'^(\w+) = (.+)$', block, re.M))
        scene["nodes"].append({"name": attrs.get("name"), "type": attrs.get("type"), "parent": attrs.get("parent"),
                               "instance": inst.group(1) if inst else None,
                               "script": script.group(1) if script else None, "props": props})
    return scene


scene_cache = {}


def scene_tree(rp):
    """Returns {node_path: {"type", "script"}} with instanced scenes expanded."""
    if rp in scene_cache:
        return scene_cache[rp]
    sc = parse_scene(res(rp))
    tree = {}
    for n in sc["nodes"]:
        if n["parent"] is None:
            path = "."
        elif n["parent"] == ".":
            path = n["name"]
        else:
            path = n["parent"] + "/" + n["name"]
        script = sc["ext"][n["script"]]["path"] if n["script"] and n["script"] in sc["ext"] else None
        entry = {"type": n["type"], "script": script, "props": n["props"]}
        if n["instance"] and n["instance"] in sc["ext"]:
            sub = scene_tree(sc["ext"][n["instance"]]["path"])
            root = sub.get(".", {})
            entry = {"type": root.get("type"), "script": script or root.get("script"), "props": root.get("props", {})}
            for sub_path, sub_entry in sub.items():
                if sub_path != ".":
                    tree[(path + "/" + sub_path) if path != "." else sub_path] = sub_entry
        tree[path] = entry
    scene_cache[rp] = tree
    return tree


def join(base, rel):
    parts = [] if base == "." else base.split("/")
    for p in rel.split("/"):
        if p == "..":
            if not parts:
                return None
            parts.pop()
        elif p and p != ".":
            parts.append(p)
    return "/".join(parts) if parts else "."


for path in project_files(".tscn"):
    rp = "res://" + os.path.relpath(path, ROOT).replace(os.sep, "/")
    sc = parse_scene(path)
    for eid, attrs in sc["ext"].items():
        if not os.path.exists(res(attrs["path"])):
            err("%s: ext_resource %s missing" % (rp, attrs["path"]))
    for eid in re.findall(r'ExtResource\("([^"]+)"\)', sc["text"]):
        if eid not in sc["ext"]:
            err("%s: ExtResource id %s not declared" % (rp, eid))
    for sid in re.findall(r'SubResource\("([^"]+)"\)', sc["text"]):
        if sid not in sc["sub"]:
            err("%s: SubResource id %s not declared" % (rp, sid))
    m = re.search(r"load_steps=(\d+)", sc["text"])
    if m and int(m.group(1)) != len(sc["ext"]) + len(sc["sub"]) + 1:
        err("%s: load_steps=%s but should be %d" % (rp, m.group(1), len(sc["ext"]) + len(sc["sub"]) + 1))
    seen = {"."}
    names_by_parent = {}
    for i, n in enumerate(sc["nodes"]):
        if n["parent"] is None:
            if i != 0:
                err("%s: second root node %s" % (rp, n["name"]))
            continue
        if n["parent"] not in seen:
            err("%s: node %s has unknown parent %s" % (rp, n["name"], n["parent"]))
        key = (n["parent"], n["name"])
        if key in names_by_parent:
            err("%s: duplicate node name %s under %s" % (rp, n["name"], n["parent"]))
        names_by_parent[key] = True
        seen.add(n["name"] if n["parent"] == "." else n["parent"] + "/" + n["name"])
        if not n["type"] and not n["instance"]:
            err("%s: node %s has no type" % (rp, n["name"]))

    # Node paths used by attached scripts.
    tree = scene_tree(rp)
    for node_path, entry in tree.items():
        sp = entry.get("script")
        if not sp or sp not in scripts or sp.startswith("res://tests/"):
            continue
        src = scripts[sp]["src"]
        refs = set(re.findall(r'\$([A-Za-z0-9_/]+)', src))
        refs |= set(re.findall(r'get_node\("([^"]+)"\)', src))
        for m in re.finditer(r'@export var (\w+): NodePath = NodePath\("([^"]+)"\)', src):
            override = entry["props"].get(m.group(1))
            refs.add(override.strip('NodePath("")') if override else m.group(2))
        for ref in refs:
            target = join(node_path, ref)
            if target is None or target not in tree:
                err("%s: script %s on node '%s' uses path '%s' which does not exist" % (rp, sp, node_path, ref))

# Scenes and resources referenced from code.
for rp, info in scripts.items():
    for p in re.findall(r'(?:preload|load|change_scene_to_file)\("(res://[^"]+)"\)', info["src"]):
        if not os.path.exists(res(p)):
            err("%s: references missing file %s" % (rp, p))
    for p in re.findall(r'const \w+ := "(res://[^"]+\.tscn)"', info["src"]):
        if not os.path.exists(res(p)):
            err("%s: references missing scene %s" % (rp, p))

# --- input actions ---------------------------------------------------------------

for rp, info in scripts.items():
    used = set(re.findall(r'is_action(?:_just)?_(?:pressed|released)\("(\w+)"\)', info["src"]))
    for args in re.findall(r'get_vector\(([^)]*)\)', info["src"]):
        used |= set(re.findall(r'"(\w+)"', args))
    used |= set(re.findall(r'\{"id": "(\w+)"', info["src"]))
    for a in sorted(used):
        if a not in actions:
            err("%s: input action '%s' is not in project.godot" % (rp, a))

# --- typed member access across the project's own classes -------------------------

def class_of(info, name):
    """Type of a member/local declared in this script, if it is one of our classes."""
    m = re.search(r"\bvar\s+%s\s*:\s*(\w+)" % re.escape(name), info["src"])
    if m:
        return m.group(1)
    m = re.search(r"\bvar\s+%s\s*:=\s*.+?\bas\s+(\w+)\s*$" % re.escape(name), info["src"], re.M)
    if m:
        return m.group(1)
    m = re.search(r"\bvar\s+%s\s*:=\s*(\w+)\.new\(\)" % re.escape(name), info["src"])
    if m:
        return m.group(1)
    m = re.search(r"\bvar\s+%s\s*:=\s*(_\w+)\(\)" % re.escape(name), info["src"])
    if m:
        ret = re.search(r"func\s+%s\([^)]*\)\s*->\s*(\w+)" % m.group(1), info["src"])
        if ret:
            return ret.group(1)
    m = re.search(r"func\s+\w+\([^)]*\b%s\s*:\s*(\w+)" % re.escape(name), info["src"])
    if m:
        return m.group(1)
    return None


# Members every project class inherits from its engine base (Node / Node3D / CanvasItem).
ENGINE_MEMBERS = {
    "position", "global_position", "rotation", "rotation_degrees", "scale", "transform", "global_transform",
    "basis", "visible", "name", "velocity", "get_tree", "get_node", "get_parent", "add_child", "queue_free",
    "get_rid", "is_in_group", "has_method", "call", "set_process", "set_physics_process", "is_physics_processing",
    "process_mode", "show", "hide", "size", "look_at", "head",
}


def has_member(cls, attr):
    info = classes.get(cls)
    if not info:
        return None  # not one of ours; skip
    if attr in ENGINE_MEMBERS:
        return True
    return attr in info["members"] or attr in info["funcs"] or attr in info["signals"] or attr in info["consts"]


checked = 0
for rp, info in scripts.items():
    if rp.startswith("res://tests/"):
        continue  # test scripts poke engine internals; they are verified by running them in Godot
    for m in re.finditer(r"\b([a-z_]\w*)((?:\.[a-zA-Z_]\w*)+)", info["src"]):
        base, chain = m.group(1), m.group(2).split(".")[1:]
        if base in ("self",):
            continue
        cls = class_of(info, base)
        if base == "SaveSystem" or base in classes:
            cls = base
        for attr in chain:
            if cls is None or cls not in classes:
                break
            ok = has_member(cls, attr)
            checked += 1
            if not ok:
                if attr in ("connect", "emit", "keys", "values", "get", "has", "size", "x", "y", "z"):
                    break
                err("%s: '%s' has no member '%s' (in %s%s)" % (rp, cls, attr, base, m.group(2)))
                break
            cls = classes[cls]["members"].get(attr) if attr in classes[cls]["members"] else None

# --- report -------------------------------------------------------------------------

print("THE LAST LIGHT - static validation")
print("  scripts: %d   scenes: %d   input actions: %d   typed member checks: %d"
      % (len(scripts), len(project_files(".tscn")), len(actions), checked))
for n in notes:
    print("  note:", n)
if errors:
    print("\nFAILED with %d problem(s):" % len(errors))
    for e in errors:
        print("  -", e)
    sys.exit(1)
print("\nAll checks passed.")
