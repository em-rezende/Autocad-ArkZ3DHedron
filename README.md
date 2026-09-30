# ArkZ3DHedron Studio v3.2

**ArkZ3DHedron Studio** is an advanced parametric tool developed in **AutoLISP** and **DCL** for AutoCAD. It allows you to create, preview, and generate complex polyhedra (Platonic, Archimedean, Catalan solids) and Geodesic Domes directly within the CAD 3D environment.

The plugin features its own vector rendering engine for real-time visualization (with support for hidden-line removal and shading) and exports to multiple geometric formats.

---

## 📸 Screenshots

### Main Dialog — Rhombicosidodecahedron Preview
![Main Dialog - Rhombicosidodecahedron](Fonts/Contents/Resources/image_1.png)

*The main dialog showing a Rhombicosidodecahedron (62 faces, 60 vertices) in the interactive vector preview, with the Geometry Setup, Output Engine, Polygons Around Vertex, Colors, and Special Operations panels.*

### Advanced Mode — Truncated Icosahedron (Soccer Ball) Preview
![Advanced Mode - Truncated Icosahedron](Fonts/Contents/Resources/image_2.png)

*The Advanced dialog displaying a Truncated Icosahedron ("Football / Soccer Ball", 32 faces, 60 vertices) in 3D Wireframe mode with Auto-Layer enabled and color assignments visible.*

### Help Dialog
![Help Dialog](Fonts/Contents/Resources/image_3.png)

*The built-in Help dialog, loaded from ArkZ3DHedron.txt, showing the table of contents and program registration information.*

---

## 📜 Credits and Origin

- **Original Author:** Petri Leskinen
- **Creation Date:** 12/8/2000 in Espoo, Finland
- **Original Email:** `leskinen.petri@luukku.com`
- **Development, Updates, and 3D Wireframe Support (v3.2):** ARK-Z Arquitetura

---

## 📸 Key Features

- 🧱 **4 Output Engines:**
  - **Polyface Mesh (Legacy):** Traditional 3D polygon meshes (universal compatibility).
  - **Sub-D Mesh (Modern):** Modern subdividable meshes native to AutoCAD.
  - **3D Solid (CSG):** Real solid models created via CSG operations and slicing planes (`SLICE`).
  - **3D Wireframe (Edges):** Geometric wireframe structure composed of **closed 3D Polylines (`3DPOLY`)** per face.
- 🎨 **Intelligent Auto-Layer System:** Automatically organizes created elements into layers by side count (`3D_POLY_3SIDES`, `3D_POLY_4SIDES`, etc.) with standardized colors.
- 🖥️ **Interactive Real-Time Preview:**
  - Vector preview window with visible/hidden face calculation (*backface culling*).
  - Rotatable via mouse drag.
  - Quick views (Top, Front, SE and SW Isometric).
  - **Wireframe** (Hidden-Line) and **Shade** (Colored Shading) modes.
- 📐 **Built-in Geometric Presets:**
  - **Platonic Solids:** Tetrahedron, Cube, Octahedron, Dodecahedron, Icosahedron.
  - **Archimedean Solids:** Cuboctahedron, Rhombicuboctahedron, Rhombicosidodecahedron, Truncated Icosahedron ("Soccer Ball").
  - **Catalan Solids:** Rhombic Dodecahedron, Rhombic Triacontahedron, Tetrakis Hexahedron.
  - **Geodesic Domes:** 1V, 2V, and 3V frequencies based on spherical projection.
  - **Custom:** Free assembly by defining the polygons around each vertex.
- ⚙️ **Advanced Geometric Operations:**
  - **Truncation:** 0% to 50% adjustment to generate truncated/dual polyhedra.
  - **Triangulation:** Recursive subdivision of faces.
  - **Color Customization:** Assign display colors by polygon type.
- 💾 **Settings Persistence:** Automatic saving of the last unit, size, draw mode, and Auto-Layer preferences between AutoCAD sessions.

---

## 🛠️ Manual Installation

1. Download the program files from the bundle folder `Fonts/Contents/Windows/`:
   - `ArkZ3DHedron.lsp` — AutoLISP source code
   - `ArkZ3DHedron.dcl` — Dialog interface definition
   - `ArkZ3DHedron.slb` — Optional slide library
   - `ArkZ3DHedron.txt` — Help text file
   - `ArkZ3DHedron.cuix` — Optional ribbon/toolbar customization
2. Copy the files to a folder included in the AutoCAD *Support File Search Path*, or keep them in the project's working folder.
3. In AutoCAD, type the `APPLOAD` command.
4. Locate and select the `ArkZ3DHedron.lsp` file and click **Load**.

### Automated Installation (Bundle / Installer)

The complete AutoCAD Application Bundle (`PackageContents.xml` + `Contents/`) is kept in the `Fonts/` folder, which is exactly what the AutoCAD Autoloader expects. To build the Windows installer:

1. Install [Inno Setup 6](https://jrsoftware.org/isinfo.php).
2. Open `Install ArkZ3DHedron.iss` in the Inno Setup Compiler and press **Compile**.
3. The setup executable is generated in the `Instalador/` folder as `ArkZ3dhedron_v_<version>_Setup.exe`.
4. Running the setup deploys the bundle to `C:\Program Files (x86)\Autodesk\ApplicationPlugins\ArkZ3dhedron.bundle` (all users) or `%APPDATA%\Autodesk\ApplicationPlugins\ArkZ3dhedron.bundle` (current user only), so the plugin is loaded automatically on the next AutoCAD start.

---

## 🚀 How to Use

Type the main command at the AutoCAD command line:

```autocad
ArkZ3DHedron
```

The dialog interface (DCL) will be displayed, allowing you to configure parameters and preview the polyhedron before generation.

---

## 📖 Interface and Feature Guide

### 1. Geometry Setup

| Parameter | Description |
| --- | --- |
| **Size** | Defines the base size of the geometry. Can be typed or picked from the screen using the `Size <` button. |
| **Edge / Radius** | Toggles whether the size value refers to the **polygon edge** or the **circumscribed sphere radius**. |
| **Center Point (X, Y, Z)** | Defines the 3D insertion coordinate for the polyhedron center. Can be picked on screen using the `Center point <` button. |

---

### 2. Output Engine

Choose how the geometry will be constructed inside the drawing:

* **Polyface Mesh (Legacy):** Creates `PFACE` entities. Lightweight and compatible with older AutoCAD versions and third-party software.
* **Sub-D Mesh (Modern):** Creates native `MESH` entities. Ideal for those who intend to apply mesh smoothing for organic modeling.
* **3D Solid (CSG):** Generates a real `3DSOLID` object. Starts from a solid block and applies slicing planes (`SLICE`) on the calculated faces.
* **3D Wireframe (Edges):** Creates only the wireframe, generating a closed `3DPOLY` for each face. Ideal for structural detailing, center axes, or templates.
* **Auto-Layer by Polygon Sides:** When active, automatically creates and assigns layers named according to the polygon's side count (e.g., `3D_POLY_3SIDES`, `3D_POLY_5SIDES`).

---

### 3. Presets and Customization

Select a pre-configured polyhedron from the **Presets** list, or build your own topology by filling the **Polygons Around Vertex** box with the side counts of the polygons meeting at each vertex (e.g., `3, 3, 3` for a Tetrahedron; `3, 4, 3, 4` for a Cuboctahedron).

---

### 4. Interactive Preview (Vector Visualization)

* **Mouse Drag:** Click and drag over the preview square to dynamically rotate the model in 3D.
* **Top / Front / SE Iso / SW Iso:** Quick view alignment buttons.
* **View / Shade:** `View` displays the structure as lines with back-face hidden-line removal. `Shade` fills the faces with the assigned colors.

---

### 5. Advanced Mode (`Advanced >`)

Click the **Advanced >** button at the bottom of the window to access the special controls:

* **Triangulation:** Recursively subdivides faces into triangles.
* **Truncation:** Slider control to apply geometric truncation (adjusting vertices toward the polyhedron center).
* **Colors:** Allows you to assign specific ACI colors per polygon type (triangles, squares, pentagons, etc.) for display in shaded mode.

---

## 📁 Project File Structure

```text
ArkZ3DHedron/
├── Fonts/                          # AutoCAD Application Bundle
│   ├── PackageContents.xml         # Bundle manifest (Autodesk Autoloader / App Store)
│   └── Contents/
│       ├── Resources/              # Icons, stylesheet, help page (Index.htm) and screenshots
│       └── Windows/                # ArkZ3DHedron.lsp, .dcl, .cuix, .slb and help .txt
├── Support/                        # Installer artwork (ARK-Z icon and wizard bitmaps)
├── Instalador/                     # Output folder for the compiled setup (.exe)
├── Install ArkZ3DHedron.iss        # Inno Setup script of the Windows installer
├── README.md                       # English documentation
└── README_ptBR.md                  # Portuguese (Brazil) documentation
```

---

## 📐 Compatibility

* **Supported Software:** AutoCAD 2012 through the most recent versions (Windows).
* **Native Units:** Supports automatic conversion and reading of the `INSUNITS` variable (mm, cm, m, inches, feet).
* **Dependencies:** No external libraries required (uses native AutoLISP/Visual LISP and DCL libraries).

---

## 📄 License and Usage

Based on the original `3Dhedron.lsp` routine by Petri Leskinen (2000). Code released for free use and modification in architectural, engineering, and 3D modeling projects.
```
