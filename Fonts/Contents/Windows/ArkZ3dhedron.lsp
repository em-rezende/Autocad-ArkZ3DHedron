;;; ============================================================================
;;; ArkZ3DHedron.lsp - Advanced Polyhedron and Geodesic Dome Generator
;;; Version: 3.5 (Image Dimensions and ILLEGAL Preview Adjustment)
;;; ============================================================================

;;; CREDITS AND ORIGIN
;;; ---------------------------------------------------------------------------
;;; Original Author: Petri Leskinen
;;; Creation Date: 12/8/2000 in Espoo, Finland
;;; Original Email: leskinen.petri@luukku.com
;;; Development, Updates, and 3D Wireframe Support (v3.2): ARK-Z Arquitetura
;;; Maintainer: Ezequiel M Rezende
;;; Project Website: https://em-rezende.github.io/


(vl-load-com)

(setq hd:global-dcl-id nil)
(setq hd:illegal-poly nil)


;;; ---------------------------------------------------------------------------
;;; FUNCTION 3DH_ShowSld
;;; Description: Displays a slide image inside a DCL tile with a background color.
;;;              Fills the tile with the specified color, then overlays the slide.
;;; Parameters:
;;;   tile   - String: the tile key where the slide will be displayed.
;;;   library- String: the slide library name (without extension).
;;;   slide  - String: the slide name to display.
;;;   color  - Integer: the background color index for the tile.
;;; Returns:   Always returns nil (princ).
;;; Usage:     (3DH_ShowSld "#img_logo" "ArkZ3DHedron" "ArkZLogo" -2)
;;; --------------------------------------------------------------------------
(defun 3DH_ShowSld (tile library slide color / x y)
  (and
    (setq x (dimx_tile tile))
    (setq y (dimy_tile tile))
    (start_image tile)
    (fill_image 0 0 x y color)
    (slide_image 0 0 x y (strcat library " (" (vl-filename-base slide) ")"))
    (end_image)
  )
  (princ)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:find-dcl-file
;;; Description: Locates the DCL file "ArkZ3DHedron.dcl" in the AutoCAD
;;;              support paths. Retries once if not found on first attempt.
;;; Parameters: None.
;;; Returns:   String: the full path to the DCL file, or nil if not found.
;;; Usage:     (hd:find-dcl-file)
;;; --------------------------------------------------------------------------
(defun hd:find-dcl-file ( / path)
  (setq path (findfile "ArkZ3DHedron.dcl"))
  (if (not path)
    (setq path (findfile "ArkZ3DHedron.dcl"))
  )
  path
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:get-unit-name
;;; Description: Returns a short string representing the current drawing
;;;              insertion units (INSUNITS system variable).
;;; Parameters: None.
;;; Returns:   String: unit abbreviation ("in", "ft", "mm", "cm", "m", etc.)
;;;            or "un" if the unit is not recognized.
;;; Usage:     (hd:get-unit-name)
;;; --------------------------------------------------------------------------
(defun hd:get-unit-name ( / u)
  (setq u (getvar "INSUNITS"))
  (cond
    ((= u 1) "in")   ((= u 2) "ft")   ((= u 4) "mm")
    ((= u 5) "cm")   ((= u 6) "m")    ((= u 8) "µin")
    ((= u 9) "mils") ((= u 10) "yd")  ((= u 14) "dm")
    ((= u 17) "km")  ('T "un")
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:save-settings
;;; Description: Saves the current dialog settings (size, draw mode, auto-layer,
;;;              edge mode, truncation) to the Windows registry using setenv.
;;; Parameters: None.
;;; Returns:   nil
;;; Usage:     (hd:save-settings)
;;; --------------------------------------------------------------------------
(defun hd:save-settings ()
  (setenv "ARKZ_3DH_SIZE" (rtos (if (numberp hdsize) hdsize 1.0)))
  (setenv "ARKZ_3DH_MODE" (vl-symbol-name drawmode))
  (setenv "ARKZ_3DH_AUTOLAYER" (if auto-layer "1" "0"))
  (setenv "ARKZ_3DH_EDGE" (if sizeedge "1" "0"))
  (setenv "ARKZ_3DH_TRUNC" (rtos (if (numberp truncn) truncn 0.0)))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:load-settings
;;; Description: Loads the saved dialog settings from the Windows registry
;;;              (previously stored by hd:save-settings).
;;; Parameters: None.
;;; Returns:   nil
;;; Usage:     (hd:load-settings)
;;; --------------------------------------------------------------------------
(defun hd:load-settings ()
  (if (getenv "ARKZ_3DH_SIZE")
    (setq hdsize (distof (getenv "ARKZ_3DH_SIZE"))))
  (if (getenv "ARKZ_3DH_MODE")
    (setq drawmode (read (getenv "ARKZ_3DH_MODE"))))
  (if (getenv "ARKZ_3DH_AUTOLAYER")
    (setq auto-layer (= (getenv "ARKZ_3DH_AUTOLAYER") "1")))
  (if (getenv "ARKZ_3DH_EDGE")
    (setq sizeedge (= (getenv "ARKZ_3DH_EDGE") "1")))
  (if (getenv "ARKZ_3DH_TRUNC")
    (setq truncn (distof (getenv "ARKZ_3DH_TRUNC"))))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:get-or-create-layer
;;; Description: Returns (and creates if necessary) a layer named after the
;;;              number of polygon sides, assigning a color based on the side
;;;              count. Sets the created layer as current if it already exists.
;;; Parameters:
;;;   poly-sides - Integer: number of sides of the polygon (e.g., 3, 4, 5...).
;;; Returns:   String: the layer name.
;;; Usage:     (hd:get-or-create-layer 4)
;;; --------------------------------------------------------------------------
(defun hd:get-or-create-layer (poly-sides / lyr-name col)
  (setq lyr-name (strcat "3D_POLY_" (itoa poly-sides) "SIDES"))
  (setq col
    (cond
      ((= poly-sides 3) 1)  ; Red
      ((= poly-sides 4) 2)  ; Yellow
      ((= poly-sides 5) 3)  ; Green
      ((= poly-sides 6) 4)  ; Cyan
      ((= poly-sides 8) 5)  ; Blue
      ((= poly-sides 10) 6) ; Magenta
      ('T 7)                 ; White
    )
  )
  (if (not (tblsearch "LAYER" lyr-name))
    (command "._-LAYER" "_M" lyr-name "_C" (itoa col) lyr-name "")
    (setvar "CLAYER" lyr-name)
  )
  lyr-name
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:v-add
;;; Description: Adds two 3D vectors.
;;; Parameters:
;;;   a, b - Lists of 3 reals representing vectors.
;;; Returns:   List of 3 reals: the sum vector, or '(0.0 0.0 0.0) on failure.
;;; Usage:     (hd:v-add '(1 2 3) '(4 5 6))
;;; --------------------------------------------------------------------------
(defun hd:v-add (a b)
  (if (and a b)
    (list (+ (car a) (car b)) (+ (cadr a) (cadr b)) (+ (caddr a) (caddr b)))
    '(0.0 0.0 0.0)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:v-sub
;;; Description: Subtracts vector b from vector a.
;;; Parameters:
;;;   a, b - Lists of 3 reals representing vectors.
;;; Returns:   List of 3 reals: the difference vector, or '(0.0 0.0 0.0).
;;; Usage:     (hd:v-sub '(4 5 6) '(1 2 3))
;;; --------------------------------------------------------------------------
(defun hd:v-sub (a b)
  (if (and a b)
    (list (- (car a) (car b)) (- (cadr a) (cadr b)) (- (caddr a) (caddr b)))
    '(0.0 0.0 0.0)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:v-scale
;;; Description: Multiplies a vector by a scalar value.
;;; Parameters:
;;;   v - List of 3 reals: the vector.
;;;   s - Real: the scalar multiplier.
;;; Returns:   List of 3 reals: the scaled vector, or '(0.0 0.0 0.0).
;;; Usage:     (hd:v-scale '(1 2 3) 2.0)
;;; --------------------------------------------------------------------------
(defun hd:v-scale (v s)
  (if (and v s (numberp s))
    (list (* (car v) s) (* (cadr v) s) (* (caddr v) s))
    '(0.0 0.0 0.0)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:v-dot
;;; Description: Computes the dot product of two 3D vectors.
;;; Parameters:
;;;   a, b - Lists of 3 reals representing vectors.
;;; Returns:   Real: the dot product, or 0.0 on failure.
;;; Usage:     (hd:v-dot '(1 2 3) '(4 5 6))
;;; --------------------------------------------------------------------------
(defun hd:v-dot (a b)
  (if (and a b)
    (+ (* (car a) (car b)) (* (cadr a) (cadr b)) (* (caddr a) (caddr b)))
    0.0
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:v-cross
;;; Description: Computes the cross product of two 3D vectors.
;;; Parameters:
;;;   a, b - Lists of 3 reals representing vectors.
;;; Returns:   List of 3 reals: the cross product vector, or '(0.0 0.0 0.0).
;;; Usage:     (hd:v-cross '(1 0 0) '(0 1 0))
;;; --------------------------------------------------------------------------
(defun hd:v-cross (a b)
  (if (and a b)
    (list (- (* (cadr a) (caddr b)) (* (caddr a) (cadr b)))
          (- (* (caddr a) (car b)) (* (car a) (caddr b)))
          (- (* (car a) (cadr b)) (* (cadr a) (car b)))
    )
    '(0.0 0.0 0.0)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:v-len
;;; Description: Computes the Euclidean length (magnitude) of a 3D vector.
;;; Parameters:
;;;   v - List of 3 reals: the vector.
;;; Returns:   Real: the vector length, or 0.0 if v is nil.
;;; Usage:     (hd:v-len '(3 4 0))
;;; --------------------------------------------------------------------------
(defun hd:v-len (v)
  (if v (sqrt (hd:v-dot v v)) 0.0)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:v-unit
;;; Description: Returns the unit vector (normalized) of a 3D vector.
;;;              Returns '(0.0 0.0 0.0) if the vector length is near zero.
;;; Parameters:
;;;   v - List of 3 reals: the vector.
;;; Returns:   List of 3 reals: the normalized vector.
;;; Usage:     (hd:v-unit '(3 4 0))
;;; --------------------------------------------------------------------------
(defun hd:v-unit (v / l)
  (setq l (hd:v-len v))
  (if (> l 1e-12)
    (hd:v-scale v (/ 1.0 l))
    '(0.0 0.0 0.0)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:plt
;;; Description: Linear interpolation between two points p1 and p2.
;;;              Returns p1 + tval * (p2 - p1).
;;; Parameters:
;;;   p1, p2 - Lists of 3 reals: the endpoint coordinates.
;;;   tval   - Real: the interpolation parameter (0.0 = p1, 1.0 = p2).
;;; Returns:   List of 3 reals: the interpolated point.
;;; Usage:     (hd:plt '(0 0 0) '(10 0 0) 0.5)
;;; --------------------------------------------------------------------------
(defun hd:plt (p1 p2 tval)
  (if (and p1 p2 (numberp tval))
    (hd:v-add p1 (hd:v-scale (hd:v-sub p2 p1) tval))
    '(0.0 0.0 0.0)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:triple-product
;;; Description: Computes the scalar triple product of three vectors: a · (b × c).
;;;              Used to determine face orientation.
;;; Parameters:
;;;   a, b, c - Lists of 3 reals representing vectors.
;;; Returns:   Real: the scalar triple product.
;;; Usage:     (hd:triple-product '(1 0 0) '(0 1 0) '(0 0 1))
;;; --------------------------------------------------------------------------
(defun hd:triple-product (a b c)
  (hd:v-dot a (hd:v-cross b c))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:rot-axis
;;; Description: Rotates a 3D point around an arbitrary axis by a given angle
;;;              (Rodrigues' rotation formula).
;;; Parameters:
;;;   p      - List of 3 reals: the point to rotate.
;;;   u-axis - List of 3 reals: the rotation axis direction vector.
;;;   deg    - Real: the rotation angle in degrees.
;;; Returns:   List of 3 reals: the rotated point.
;;; Usage:     (hd:rot-axis '(1 0 0) '(0 0 1) 90.0)
;;; --------------------------------------------------------------------------
(defun hd:rot-axis (p u-axis deg / rad c s u p-dot-u u-cross-p)
  (if (or (not p) (not u-axis) (not (numberp deg)) (< (hd:v-len u-axis) 1e-9))
    p
    (progn
      (setq rad (* deg (/ pi 180.0))
            c (cos rad)
            s (sin rad)
            u (hd:v-unit u-axis)
            p-dot-u (hd:v-dot p u)
            u-cross-p (hd:v-cross u p)
      )
      (hd:v-add
        (hd:v-add (hd:v-scale p c) (hd:v-scale u-cross-p s))
        (hd:v-scale u (* p-dot-u (- 1.0 c)))
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:rot-xy
;;; Description: Rotates a 3D point around the X and Y axes by the specified
;;;              angles (in degrees). Used for the interactive preview orientation.
;;; Parameters:
;;;   p    - List of 3 reals: the point to rotate.
;;;   rotx - Real: rotation angle around the X axis in degrees.
;;;   roty - Real: rotation angle around the Y axis in degrees.
;;; Returns:   List of 3 reals: the rotated point.
;;; Usage:     (hd:rot-xy '(1 0 0) 35.26 -45.0)
;;; --------------------------------------------------------------------------
(defun hd:rot-xy (p rotx roty / radx rady cx sx cy sy x y z x1 y1 z1)
  (if (or (not p) (not (numberp rotx)) (not (numberp roty)))
    '(0.0 0.0 0.0)
    (progn
      (setq radx (* rotx (/ pi 180.0))
            rady (* roty (/ pi 180.0))
            cx (cos radx) sx (sin radx)
            cy (cos rady) sy (sin rady)
            x (car p) y (cadr p) z (cond ((caddr p)) (0.0))
            y1 (- (* y cx) (* z sx))
            z1 (+ (* y sx) (* z cx))
            x1 (+ (* x cy) (* z1 sy))
            z1 (- (* z1 cy) (* x sy))
      )
      (list x1 y1 z1)
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:acos
;;; Description: Returns the arc cosine of a number, in degrees.
;;;              Clamps input to the valid domain [-1.0, 1.0].
;;; Parameters:
;;;   x - Real: the cosine value.
;;; Returns:   Real: the angle in degrees (0.0 to 180.0).
;;; Usage:     (hd:acos 0.5)
;;; --------------------------------------------------------------------------
(defun hd:acos (x)
  (cond
    ((not (numberp x)) 0.0)
    ((<= x -1.0) 180.0)
    ((>= x 1.0) 0.0)
    ('T (* (/ 180.0 pi) (atan (sqrt (max 0.0 (- 1.0 (* x x)))) x)))
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:draw-ilegal-vector
;;; Description: Draws the word "ILLEGAL" as vector graphics inside the preview
;;;              tile, used when an impossible polyhedron configuration is requested.
;;;              Each character is drawn with double-stroke segments for thickness.
;;; Parameters: None.
;;; Returns:   nil
;;; Usage:     (hd:draw-ilegal-vector)
;;; --------------------------------------------------------------------------
(defun hd:draw-ilegal-vector ( / mx my w h spacing total-w x0 y0 col x draw-seg)
  (setq mx (dimx_tile "previewimage")
        my (dimy_tile "previewimage")
  )
  (if (and mx my (> mx 0) (> my 0))
    (progn
      (setq col 1 ; Red color
            total-w (* mx 0.80)
            w (/ total-w 7.5)
            spacing (* w 0.3)
            h (* w 1.5)
            x0 (/ (- mx total-w) 2.0)
            y0 (/ (- my h) 2.0)
      )
      
      (defun draw-seg (lx ly x1 y1 x2 y2)
        (vector_image
          (fix (+ lx (* x1 w)))
          (fix (+ ly (* y1 h)))
          (fix (+ lx (* x2 w)))
          (fix (+ ly (* y2 h)))
          col
        )
        ;; Double stroke for thickness
        (vector_image
          (fix (+ lx (* x1 w) 1))
          (fix (+ ly (* y1 h)))
          (fix (+ lx (* x2 w) 1))
          (fix (+ ly (* y2 h)))
          col
        )
      )

      ;; Letter 'I'
      (setq x x0)
      (draw-seg x y0 0.0 0.0 1.0 0.0)
      (draw-seg x y0 0.5 0.0 0.5 1.0)
      (draw-seg x y0 0.0 1.0 1.0 1.0)

      ;; Letter 'L'
      (setq x (+ x w spacing))
      (draw-seg x y0 0.0 0.0 0.0 1.0)
      (draw-seg x y0 0.0 1.0 1.0 1.0)

      ;; Letter 'E'
      (setq x (+ x w spacing))
      (draw-seg x y0 0.0 0.0 0.0 1.0)
      (draw-seg x y0 0.0 0.0 1.0 0.0)
      (draw-seg x y0 0.0 0.5 0.8 0.5)
      (draw-seg x y0 0.0 1.0 1.0 1.0)

      ;; Letter 'G'
      (setq x (+ x w spacing))
      (draw-seg x y0 1.0 0.0 0.0 0.0)
      (draw-seg x y0 0.0 0.0 0.0 1.0)
      (draw-seg x y0 0.0 1.0 1.0 1.0)
      (draw-seg x y0 1.0 1.0 1.0 0.5)
      (draw-seg x y0 1.0 0.5 0.5 0.5)

      ;; Letter 'A'
      (setq x (+ x w spacing))
      (draw-seg x y0 0.0 1.0 0.5 0.0)
      (draw-seg x y0 0.5 0.0 1.0 1.0)
      (draw-seg x y0 0.25 0.5 0.75 0.5)

      ;; Letter 'L'
      (setq x (+ x w spacing))
      (draw-seg x y0 0.0 0.0 0.0 1.0)
      (draw-seg x y0 0.0 1.0 1.0 1.0)
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION fillpreview
;;; Description: Fills a preview face with a solid color by scanning horizontal
;;;              scanlines and computing the intersection span of the face edges.
;;;              Also draws the face outline in white (color 7).
;;; Parameters:
;;;   lst - List: list of edge segments (each segment is a list of two 2D points).
;;;   c   - Color: color index or name ("byblock", "bylayer", or a color string).
;;; Returns:   nil
;;; Usage:     (fillpreview (facetolines plist2d_face) "red")
;;; --------------------------------------------------------------------------
(defun fillpreview (lst c / ylst y0 y1 lst2 line n xlist po0 po1 col-idx)
  (setq ylst (mapcar 'cadr (apply 'append lst))
        y0 (1+ (apply 'min ylst))
        y1 (apply 'max ylst)
        lst2 lst
        col-idx
        (cond
          ((numberp c) c)
          ((= c "byblock") 7)
          ((= c "bylayer") -15)
          ((setq n (member c collist)) (- (length collist) (length n)))
          ((read c) (atoi c))
          ('T 7)
        )
        line (car lst2)
        n (if line (cadr (car line)) 0)
  )
  (while (< y0 y1)
    (setq xlist (mapcar '(lambda (line) (car (inters (car line) (cadr line) (list 0 y0) (list 1000 y0)))) lst2)
          xlist (mapcar 'fix (filterlist 'eval xlist))
    )
    (if xlist (vector_image (apply 'min xlist) y0 (apply 'max xlist) y0 col-idx))
    (setq y0 (1+ y0))
    (if (< n y0)
      (while (and line (< (cadr (cadr line)) y0))
        (setq lst2 (cdr lst2) line (car lst2) n (if line (cadr (car line)) 0))
      )
    )
  )
  (foreach line lst
    (setq po0 (car line) po1 (last line))
    (vector_image (car po0) (cadr po0) (car po1) (cadr po1) 7)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION fillpreview_bg
;;; Description: Fills a preview face with the background color (black) by
;;;              scanning horizontal scanlines, computing the intersection span.
;;;              Used when the preview is in wireframe/hidden-line mode.
;;; Parameters:
;;;   lst - List: list of edge segments.
;;; Returns:   nil
;;; Usage:     (fillpreview_bg (facetolines plist2d_face))
;;; --------------------------------------------------------------------------
(defun fillpreview_bg (lst / ylst y0 y1 lst2 line n xlist)
  (setq ylst (mapcar 'cadr (apply 'append lst))
        y0 (1+ (apply 'min ylst))
        y1 (apply 'max ylst)
        lst2 lst
        line (car lst2)
        n (if line (cadr (car line)) 0)
  )
  (while (< y0 y1)
    (setq xlist (mapcar '(lambda (line) (car (inters (car line) (cadr line) (list 0 y0) (list 1000 y0)))) lst2)
          xlist (mapcar 'fix (filterlist 'eval xlist))
    )
    (if xlist (vector_image (apply 'min xlist) y0 (apply 'max xlist) y0 0))
    (setq y0 (1+ y0))
    (if (< n y0)
      (while (and line (< (cadr (cadr line)) y0))
        (setq lst2 (cdr lst2) line (car lst2) n (if line (cadr (car line)) 0))
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION drawpreview
;;; Description: Main preview renderer. Projects the 3D polyhedron vertices to
;;;              2D using the current rotx/roty angles, performs hidden-line
;;;              removal via back-face culling and depth sorting, and then
;;;              renders filled or wireframe faces in the preview tile.
;;;              Also handles truncation (dualization) before rendering.
;;; Parameters:
;;;   plist - List of 3D points: the polyhedron vertices.
;;;   flist - List of faces: each face is a list of vertex indices.
;;;   rt    - Real: the circumradius of the polyhedron.
;;; Returns:   nil
;;; Usage:     (drawpreview plist flist rt)
;;; --------------------------------------------------------------------------
(defun drawpreview (plist flist rt / cen rel plist_rot plist2d face plist2d_face a b c dx1 dy1 dx2 dy2 cross z_avg faces_to_draw item po0 po1 modetilelist tr)
  (foreach n (setq modetilelist '("View" "Shade" "OK" "Cancel" "0" "1" "2" "3" "4"))
    (mode_tile n 1)
  )
  (if (and (not hd:illegal-poly) rt (numberp rt) (> rt 0.0) plist flist (not (member nil plist)))
    (if (> truncn 0.0)
      (progn
        (dualize truncn)
        (setq tr truncn truncn 0.0)
        (drawpreview dplist dflist rt)
        (setq truncn tr tr nil)
      )
      (progn
        (set_tile "plist" (strcat "Vertices : " (itoa (length plist))))
        (set_tile "flist" (strcat "Faces : " (itoa (length flist))))
        (if updatepolcolor (updatepolcolor))
        
        (setq maxx (dimx_tile "previewimage")
              maxy (dimy_tile "previewimage")
        )
        (start_image "previewimage")
        (fill_image 0 0 maxx maxy 0)
        
        (setq cen (/ maxx 2.0)
              rel (* 0.8 (/ cen rt))
              plist_rot (mapcar '(lambda (po) (hd:rot-xy po rotx roty)) plist)
              plist2d (mapcar '(lambda (po)
                                 (list (fix (+ cen (* rel (car po))))
                                       (fix (- cen (* rel (cadr po))))
                                       (caddr po))
                               ) plist_rot)
        )
        
        (setq faces_to_draw nil)
        (foreach face flist
          (if (and (listp face) (>= (length face) 3))
            (progn
              (setq plist2d_face (mapcar '(lambda (x) (nth x plist2d)) face))
              (if (not (member nil plist2d_face))
                (progn
                  (setq a (car plist2d_face)
                        b (cadr plist2d_face)
                        c (caddr plist2d_face)
                        dx1 (- (car b) (car a))
                        dy1 (- (cadr b) (cadr a))
                        dx2 (- (car c) (car a))
                        dy2 (- (cadr c) (cadr a))
                        cross (- (* dx1 dy2) (* dy1 dx2))
                  )
                  (if (< cross 0.0)
                    (progn
                      (setq z_avg (/ (apply '+ (mapcar 'caddr plist2d_face)) (float (length face))))
                      (setq faces_to_draw (append faces_to_draw (list (list z_avg face plist2d_face))))
                    )
                  )
                )
              )
            )
          )
        )
        
        (setq faces_to_draw
          (vl-sort faces_to_draw
            '(lambda (f1 f2) (< (car f1) (car f2)))
          )
        )
        
        (foreach item faces_to_draw
          (setq face (cadr item)
                plist2d_face (caddr item)
          )
          (if previewfill
            (fillpreview (facetolines plist2d_face) (eval (polcolorname (length face))))
            (progn
              (fillpreview_bg (facetolines plist2d_face))
              (foreach line (facetolines plist2d_face)
                (setq po0 (car line) po1 (cadr line))
                (if (and po0 po1)
                  (vector_image (car po0) (cadr po0) (car po1) (cadr po1) 7)
                )
              )
            )
          )
        )
        (end_image)
      )
    )
    (clearpreview)
  )
  (foreach n modetilelist (mode_tile n 0))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION clearpreview
;;; Description: Clears the preview image tile. If the current polyhedron is
;;;              illegal, displays the "ILLEGAL" vector graphic and updates
;;;              the info tiles accordingly.
;;; Parameters: None.
;;; Returns:   nil
;;; Usage:     (clearpreview)
;;; --------------------------------------------------------------------------
(defun clearpreview ()
  (setq maxx (dimx_tile "previewimage")
        maxy (dimy_tile "previewimage")
  )
  (if (and maxx maxy (> maxx 0) (> maxy 0))
    (progn
      (start_image "previewimage")
      (fill_image 0 0 maxx maxy 0)
      (if hd:illegal-poly
        (progn
          (hd:draw-ilegal-vector)
        )
      )
      (end_image)
    )
  )
  (if hd:illegal-poly
    (progn
      (set_tile "flist" "Illegal")
      (set_tile "plist" "polyhedron")
    )
    (progn
      (set_tile "flist" "")
      (set_tile "plist" "")
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION updatedialst
;;; Description: Updates the dialog tiles based on the current polygon list.
;;;              Sets the first polygon edit box, updates the popup lists,
;;;              rebuilds the polyhedron geometry, and refreshes the preview.
;;; Parameters:
;;;   in-lst - List: the polygon configuration list (e.g., '(3 3 3 nil nil)).
;;; Returns:   nil
;;; Usage:     (updatedialst '(4 4 4 nil nil))
;;; --------------------------------------------------------------------------
(defun updatedialst (in-lst / safe-num-lst n val key)
  (setq safe-num-lst (vl-remove-if-not 'numberp in-lst))
  (if (and safe-num-lst (car safe-num-lst))
    (set_tile "0" (rtos (car safe-num-lst)))
    (set_tile "0" "3")
  )
  (foreach n '(1 2 3 4)
    (setq val (nth n in-lst))
    (setq key (itoa n))
    (if (and val (assoc val popuplist))
      (set_tile key (cdr (assoc val popuplist)))
      (set_tile key "0")
    )
  )
  (formhedron in-lst)
  (drawpreview plist flist rt)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd_set_action_tiles
;;; Description: Registers all action_tile callbacks for the main dialog.
;;;              Handles user interactions for size, view angles, presets,
;;;              polygon selection, preview interaction, shading, truncation,
;;;              triangulation, and dialog navigation (Advanced/Simple/OK/Cancel).
;;; Parameters: None (uses global dialog state).
;;; Returns:   nil
;;; Usage:     (hd_set_action_tiles)
;;; --------------------------------------------------------------------------
(defun hd_set_action_tiles (/ n c selected-preset)
  (set_tile "unit_lbl" (hd:get-unit-name))
  (set_tile "autolayer" (if auto-layer "1" "0"))
  (action_tile "autolayer" "(setq auto-layer (= $value \"1\"))")
  
  (action_tile "mesh" "(setq drawmode 'drawmesh)")
  (action_tile "subdmesh" "(setq drawmode 'drawsubdmesh)")
  (action_tile "solid" "(setq drawmode 'drawsolid)")
  (action_tile "wireframe" "(setq drawmode 'drawwireframe)")
  
  (set_tile
    (cond
      ((equal drawmode 'drawmesh) "mesh")
      ((equal drawmode 'drawsubdmesh) "subdmesh")
      ((equal drawmode 'drawsolid) "solid")
      ((equal drawmode 'drawwireframe) "wireframe")
      ('T "mesh")
    )
    "1"
  )

  (action_tile "v_top" "(setq rotx 0.0 roty 0.0)(drawpreview plist flist rt)")
  (action_tile "v_front" "(setq rotx -90.0 roty 0.0)(drawpreview plist flist rt)")
  (action_tile "v_se" "(setq rotx 35.26 roty -45.0)(drawpreview plist flist rt)")
  (action_tile "v_sw" "(setq rotx 35.26 roty 45.0)(drawpreview plist flist rt)")

  (action_tile "preset"
    "(setq selected-preset (nth (atoi $value) prelist))
     (cond
       ((listp selected-preset) (setq lst selected-preset))
       ((equal selected-preset 'geo1v) (hd:build-geodesic 1))
       ((equal selected-preset 'geo2v) (hd:build-geodesic 2))
       ((equal selected-preset 'geo3v) (hd:build-geodesic 3))
       ('T (setq lst '(3 3 3 nil nil)))
     )
     (updatedialst lst)"
  )
  (action_tile "0"
    "(if (and (setq n (atoi $value)) (> n 2))
       (setq lst (append (list n) (cdr lst)))
     )
     (updatedialst lst)"
  )
  (foreach n '("1" "2" "3" "4")
    (action_tile n "(diaupdatelist $key $value)")
  )
  (set_tile "hdsize" (rtos (if (numberp hdsize) hdsize 1.0)))
  (action_tile "hdsize" "(if (setq n (distof $value))(setq hdsize n))(set_tile $key (rtos hdsize))")
  (action_tile "picksize" "(done_dialog 5)")
  (action_tile "edge" "(setq sizeedge 'T)")
  (action_tile "radius" "(setq sizeedge 'nil)")
  (setq c 0)
  (foreach n '("X" "Y" "Z")
    (set_tile n (rtos (nth c cepoint)))
    (action_tile n (strcat "(if (setq n (distof $value))(setnthlist " (itoa c) " n 'cepoint))(set_tile $key (rtos (nth " (itoa c) " cepoint)))"))
    (setq c (1+ c))
  )
  (action_tile "pickpoint" "(done_dialog 4)")
  (action_tile "View" "(formhedron lst)(setq previewfill nil)(drawpreview plist flist rt)")
  (setq n "previewimage" maxx (dimx_tile n) maxy (dimy_tile n))
  (action_tile n "(setq rotx (* 90.0 (/ (- (* 0.5 maxx) $y) 1.0 maxx)) roty (- (* 180.0 (/ $x 1.0 maxy)) 90))(drawpreview plist flist rt)")
  (action_tile "advanced" "(done_dialog 2)")
  (updatedialst lst)
  (action_tile "OK" "(done_dialog 1)")
  (action_tile "Cancel" "(setq plist nil flist nil)(done_dialog 0)")
  (action_tile "help" "(ArkZ3DHedron_Help)")
  (action_tile "Shade" "(formhedron lst)(setq previewfill 'T)(drawpreview plist flist rt)")
  (action_tile "trunc" "(if (setq n (distof $value))(setq truncn (max 0.0 (min 1.0 n))))(updatetrunc)")
  (set_tile "trunc" (rtos (if (numberp truncn) truncn 0.0)))
  (action_tile "truncation" "(setq truncn (/ (distof $value) 10000.0))(updatetrunc)")
  (set_tile "truncation" (rtos (* 10000 (if (numberp truncn) truncn 0.0))))
  (action_tile "triang" "(setq triangn (atoi $value))(formhedron lst)(repeat triangn (triangulate))(drawpreview plist flist rt)")
  (action_tile "simple" "(done_dialog 3)")
)

;;;---------------------------------------------------------------------------
;;; FUNCTION polcolorname
;;; Description: Returns the symbol used to store the color of a polygon with
;;;              a given number of sides (e.g., color3, color4...).
;;; Parameters:
;;;   c - Integer: number of polygon sides.
;;; Returns:   Symbol: the color variable symbol (e.g., 'color3).
;;; Usage:     (polcolorname 4) => 'color4
;;; --------------------------------------------------------------------------
(defun polcolorname (c)
  (read (strcat "color" (itoa c)))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:build-geodesic
;;; Description: Builds a geodesic dome based on an icosahedron base, applying
;;;              the specified frequency (1V, 2V, or 3V) via repeated triangle
;;;              subdivision, then normalizes all vertices to the unit sphere.
;;; Parameters:
;;;   freq - Integer: geodesic frequency (1, 2, or 3).
;;; Returns:   nil
;;; Usage:     (hd:build-geodesic 2)
;;; --------------------------------------------------------------------------
(defun hd:build-geodesic (freq / ico-v ico-f sub-v sub-f p1 p2 p3 i j)
  (setq lst '(3 3 3 3 3))
  (formhedron lst)
  (if (= freq 1)
    nil
    (repeat (1- freq)
      (triangulate)
    )
  )
  (setq plist (mapcar '(lambda (v) (hd:v-scale (hd:v-unit v) 1.0)) plist))
  (drawpreview plist flist rt)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hd:init-logo
;;; Description: Initializes the logo and separator images in the DCL dialog.
;;;              Disables the paragraph tile (#arkz) and displays the logo and
;;;              separator slides on their respective tiles.
;;; Parameters: None.
;;; Returns:   nil
;;; Usage:     (hd:init-logo)
;;; --------------------------------------------------------------------------
(defun hd:init-logo ()
  (mode_tile "#arkz" 1)
  (3DH_ShowSld "#img_logo" "ArkZ3DHedron" "ArkZLogo" -2)
  (3DH_ShowSld "sep1" "ArkZ3DHedron" "Separato" -2)
  (3DH_ShowSld "sep2" "ArkZ3DHedron" "Separato" -2)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION c:ArkZ3DHedron
;;; Description: Main command entry point. Loads settings, initializes the
;;;              dialog, manages the main event loop (including Advanced and
;;;              Simple dialogs), and renders the final polyhedron using the
;;;              selected output engine. Handles errors and cleans up state.
;;; Parameters: None (interactive command).
;;; Returns:   nil
;;; Usage:     Command: ArkZ3DHedron
;;; --------------------------------------------------------------------------
(defun c:ArkZ3DHedron ( / previewfill *error* allhedron old_layer old_cmdecho old_osmode dcl_file n dummy tr rel generated-ok)
  (setq old_cmdecho (getvar "CMDECHO")
        old_osmode  (getvar "OSMODE")
        generated-ok nil
        hd:illegal-poly nil)
  (setvar "CMDECHO" 0)
  (command "_.UNDO" "_begin")

  (hd:load-settings)
  (if (not auto-layer) (setq auto-layer nil))

  (defun *error* (msg)
    (if (and hd:global-dcl-id (> hd:global-dcl-id 0))
      (progn
        (vl-catch-all-apply 'done_dialog '(0))
        (vl-catch-all-apply 'unload_dialog (list hd:global-dcl-id))
        (setq hd:global-dcl-id nil)
      )
    )
    (if old_osmode (setvar "OSMODE" old_osmode))
    (if old_cmdecho (setvar "CMDECHO" old_cmdecho))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*")))
      (princ (strcat "\nError in ArkZ3DHedron: " msg))
    )
    (command "_.UNDO" "_end")
    (princ)
  )

  (if (or (not lst) (not (listp lst)))
    (setq lst '(3 3 3 nil nil))
    (while (< (length lst) 5)
      (setq lst (append lst (list nil)))
    )
  )

  (setq cepoint
    (cond
      ((not cepoint) '(0.0 0.0 0.0))
      ((not (listp cepoint)) '(0.0 0.0 0.0))
      ((= (length cepoint) 2) (append cepoint (list 0.0)))
      ('T (append cepoint))
    )
  )

  (if (not (numberp hdsize)) (setq hdsize 1.0))
  (if (not drawmode) (setq drawmode 'drawmesh))

  (setq dflist nil dplist nil truncn 0.0 polcolor nil updatepolcolor nil
        collist '("byblock" "red" "yellow" "green" "cyan" "blue" "magenta" "white")
        sizeedge 'T
        old_cecolor (getvar "CECOLOR")
        n (getvar "CLAYER")
        old_layer (entget (tblobjname "LAYER" n))
        dummy (command "._-LAYER" "_on" n "_unlock" n "")
        n (/ (sqrt 2.0) 2.0)
        allhedron
        (list
          (list '(4 3 3) n
            (list '(0.5 0.5 0) '(-0.5 0.5 0) '(-0.5 -0.5 0) '(0.5 -0.5 0) (list 0 0 n))
            (list '(0 1 2 3) '(0 4 1) '(1 4 2) '(2 4 3) '(0 3 4))
          )
          (list '(5 3 3) 0.95105652
            (list '(0.0 -0.85065081 0.42532540)
                  '(0.80901699 -0.26286556 0.42532540)
                  '(0.5 0.68819096 0.42532540)
                  '(-0.5 0.68819096 0.42532540)
                  '(-0.80901699 -0.26286556 0.42532540)
                  '(0.0 0.0 0.95105652))
            (list '(0 1 2 3 4) '(0 5 1) '(1 5 2) '(2 5 3) '(3 5 4) '(0 4 5))
          )
        )
        prelist
        (list 'lst
          '(3 3 3 nil nil)
          '(4 4 4 nil nil)
          '(3 3 3 3 nil)
          '(5 5 5 nil nil)
          '(3 3 3 3 3) 'lst
          '(3 4 3 4 nil)
          '(3 4 4 4 nil)
          '(4 5 4 3 nil)
          '(5 6 6 nil nil) 'lst
          '(4 4 4 nil nil)
          '(4 4 4 nil nil)
          '(3 3 3 3 nil)   'lst
          'geo1v 'geo2v 'geo3v
        )
        rotx 35.26 roty -45.0
        hddia "hedron"
        popuplist (list (cons nil "0") '(3 . "1") '(4 . "2") '(5 . "3") '(6 . "4") '(7 . "5") '(8 . "6") '(10 . "7"))
  )

  (setq dcl_file (hd:find-dcl-file))

  (if (not dcl_file)
    (alert "File 'ArkZ3DHedron.dcl' was not found in the AutoCAD support paths.")
    (progn
	 (setq hd:global-dcl-id (load_dialog dcl_file))
      (if (not (new_dialog hddia hd:global-dcl-id))
        (alert "Could not load the ArkZ3DHedron.dcl dialog box.")
        (progn
	      ;; ---------------------------------------------------------	
          ;; Initialize controls and display logo and separators
          (mode_tile "#arkz" 1)
          (3DH_ShowSld "#img_logo" "ArkZ3dhedron" "ArkZLogo" -2)
          (3DH_ShowSld "sep1" "ArkZ3dhedron" "Separato" -2)
          (3DH_ShowSld "sep2" "ArkZ3dhedron" "Separato" -2)
          ;; ---------------------------------------------------------
          (while
            (progn
              (hd_set_action_tiles)
              (setq n (start_dialog))
              (cond
                ((= n 2)
                 (setq hddia "hedronadvanced")
                 (new_dialog hddia hd:global-dcl-id)
	             (hd:init-logo)
                 (if (not truncn) (setq truncn 0.0))
                 (defun updatetrunc ()
                   (action_tile "trunc" "(if (setq n (distof $value))(setq truncn (max 0.0 (min 1.0 n))))(updatetrunc)")
                   (action_tile "truncation" "(setq truncn (/ (distof $value) 10000.0))(updatetrunc)")
                   (set_tile "trunc" (rtos truncn))
                   (set_tile "truncation" (rtos (* 10000 truncn)))
                   (clearpreview)
                 )
                 (action_tile "simple" "(done_dialog 3)")
                 (updatetrunc)
                 (action_tile "triang" "(setq triangn (atoi $value))(formhedron lst)(repeat triangn (triangulate))(drawpreview plist flist rt)")
                 (defun updatepolcolor (/ c c2 cc lst2 n)
                   (if (not polcolor)
                     (progn
                       (setq lst2 (mapcar 'length (if dflist (append dflist) (append flist))))
                       (while lst2
                         (setq n (apply 'min lst2)
                               lst2 (filterlist '(lambda (c) (/= c n)) lst2)
                               polcolor (append polcolor (list n))
                         )
                       )
                       (foreach c polcolor
                         (if (not (eval (polcolorname c))) (set (polcolorname c) "bylayer"))
                       )
                     )
                   )
                   (foreach cc '("0" "1" "2" "3")
                     (setq c2 (nth (atoi cc) polcolor))
                     (mode_tile (strcat "c" cc) (if c2 0 1))
                     (mode_tile (strcat "i" cc) (if c2 0 1))
                     (set_tile (strcat "c" cc) (if c2 (eval (polcolorname c2)) ""))
                     (if c2
                       (progn
                         (setq c (eval (polcolorname c2)) n (strcat "i" cc))
                         (start_image n)
                         (fill_image 0 0 (dimx_tile n) (dimy_tile n)
                           (cond
                             ((= c "bylayer") 0)
                             ((= c "byblock") 7)
                             ((setq n (member c collist)) (- (length collist) (length n)))
                             ('T (atoi c))
                           )
                         )
                         (end_image)
                         (action_tile (strcat "i" cc) "(if (setq c (acad_colordlg 256))(changepolcolor $key c))")
                         (action_tile (strcat "c" cc) "(changepolcolor $key $value)")
                         (set_tile (strcat "t" cc)
                           (cond ((= c2 3) "Triangles :")
                                 ((= c2 4) "Rectangles :")
                                 ((= c2 5) "Pentagons :")
                                 ((= c2 6) "Hexagons :")
                                 ((= c2 8) "Octagons :")
                                 ('T (strcat (itoa c2) "-angles :"))
                           )
                         )
                       )
                       (progn
                         (set_tile (strcat "t" cc) "        ")
                         (start_image (setq n (strcat "i" cc)))
                         (fill_image 0 0 (dimx_tile n) (dimy_tile n) -15)
                         (end_image)
                       )
                     )
                   )
                 )
                 (action_tile "Shade" "(formhedron lst)(setq previewfill 'T)(drawpreview plist flist rt)")
                 (updatepolcolor)
                 (defun changepolcolor (a b / n)
                   (if (= (type a) 'STR) (setq a (atoi (substr a 2))))
                   (if (numberp b) (setq b (rtos (abs b))))
                   (setq n (nth a polcolor)
                         b (strcase b 0)
                         b (cond
                             ((member b collist) b)
                             ((wcmatch b "-*,byl*") "bylayer")
                             ((= b "256") "bylayer")
                             ((setq dummy (nth (atoi b) collist)) dummy)
                             ('T b)
                           )
                   )
                   (set (polcolorname n) b)
                   (set_tile (strcat "c" (itoa a)) b)
                   (start_image (setq n (strcat "i" (itoa a))))
                   (fill_image 0 0 (dimx_tile n) (dimy_tile n)
                     (cond
                       ((= b "bylayer") 0)
                       ((= b "byblock") 7)
                       ((setq n (member c collist)) (- (length collist) (length n)))
                       ('T (atoi b))
                     )
                   )
                   (end_image)
                 )
                 'T
                )
                ((= n 3)
                 (setq updatepolcolor nil hddia "hedron" polcolor nil truncn 0.0 previewfill nil)
                 (new_dialog hddia hd:global-dcl-id)
				 (hd:init-logo)
                 (action_tile "advanced" "(done_dialog 2)")
                 (setq updatepolcolor nil polcolor nil truncn 0.0)
                 'T
                )
                ((= n 4)
                 (if (setq n (getpoint cepoint)) (setq cepoint n))
                 (new_dialog hddia hd:global-dcl-id)
				 (hd:init-logo)
                 'T
                )
                ((= n 5)
                 (if (setq n (getdist "\nDistance : ")) (setq hdsize n))
                 (new_dialog hddia hd:global-dcl-id)
				 (hd:init-logo)
                 (set_tile "hdsize" (rtos hdsize))
                 'T
                )
                ('T nil)
              )
            )
          )
          (unload_dialog hd:global-dcl-id)
          (setq hd:global-dcl-id nil)
          
          (hd:save-settings)

          (setvar "OSMODE" 0)
          (cond
            ((/= n 1) nil)
            ((and (not hd:illegal-poly) (numberp rt) (> rt 0.0) (= truncn 0.0) plist flist (not (member nil plist)))
             (setq rel (if sizeedge (eval hdsize) (/ hdsize rt))
                   plist (mapcar '(lambda (po) (if po (hd:v-add (hd:v-scale po rel) cepoint) cepoint)) plist)
                   dummy ((eval drawmode) plist flist)
                   generated-ok T
             )
            )
            ((and (not hd:illegal-poly) (numberp rt) (> rt 0.0)
                  (progn
                    (if (not dflist) (dualize truncn))
                    (setq rel (if sizeedge (eval hdsize) (/ hdsize rt))
                          dplist (mapcar '(lambda (po) (if po (hd:v-add (hd:v-scale po rel) cepoint) cepoint)) dplist)
                    )
                    ((eval drawmode) dplist dflist)
                    T
                  ))
             (setq generated-ok T)
            )
          )
        )
      )
    )
  )

  (if polcolor (setvar "CECOLOR" old_cecolor))
  (if old_layer (entmod old_layer))
  (setvar "OSMODE" old_osmode)
  (setvar "CMDECHO" old_cmdecho)
  (command "_.UNDO" "_end")

  (if (= n 1)
    (if generated-ok
      (princ "\nPolyhedron generated successfully!")
      (princ "\nIllegal polyhedron - impossible to construct!")
    )
  )
  (princ)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION diaupdatelist
;;; Description: Updates the polygon list based on a popup list selection.
;;;              Maps the popup index to a polygon side count and updates
;;;              the dialog and preview accordingly.
;;; Parameters:
;;;   a - String: the tile key (index in the list).
;;;   b - String: the selected popup item index.
;;; Returns:   nil
;;; Usage:     (diaupdatelist "2" "3")
;;; --------------------------------------------------------------------------
(defun diaupdatelist (a b / idx val)
  (setq idx (atoi a)
        val (car (nth (atoi b) popuplist))
        lst (setnthlist idx val lst)
  )
  (updatedialst lst)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION setnthlist
;;; Description: Returns a new list where the n-th element is replaced by x.
;;; Parameters:
;;;   n    - Integer: zero-based index of the element to replace.
;;;   x    - The new value.
;;;   llst - List: the original list.
;;; Returns:   List: the modified list.
;;; Usage:     (setnthlist 2 'foo '(a b c d))
;;; --------------------------------------------------------------------------
(defun setnthlist (n x llst / a)
  (setq a -1)
  (mapcar '(lambda (d)
             (setq a (1+ a))
             (if (= a n) x d)
           ) llst)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION nopreview
;;; Description: Attempts to form a polyhedron from the current list. If the
;;;              configuration exists in the preset database, forms it; otherwise
;;;              clears the preview.
;;; Parameters: None.
;;; Returns:   nil
;;; Usage:     (nopreview)
;;; --------------------------------------------------------------------------
(defun nopreview ()
  (if (assoc (setq lst2 (filterlist 'eval lst)) allhedron)
    (formhedron lst2)
    (if (assoc (reverse lst2) allhedron)
      (formhedron lst2)
      (setq plist nil flist nil)
    )
  )
  (if (and (not hd:illegal-poly) flist rt plist)
    (progn
      (if updatepolcolor (updatepolcolor))
      (drawpreview plist flist rt)
    )
    (clearpreview)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION formhedron
;;; Description: Core polyhedron construction engine. Takes a list of polygon
;;;              side counts (e.g., '(3 3 3 nil nil)) and attempts to build a
;;;              convex polyhedron where each vertex has the specified sequence
;;;              of polygons around it. Calculates the circumradius, generates
;;;              polygon rings, aligns and rotates them to share edges, and
;;;              validates the resulting topology.
;;; Parameters:
;;;   in-lst - List: polygon side counts for each face around a vertex.
;;; Returns:   nil (sets global plist, flist, rt, and hd:illegal-poly).
;;; Usage:     (formhedron '(4 4 4 nil nil))
;;; --------------------------------------------------------------------------
(defun formhedron (in-lst / clean-lst lst2 a x n po nohedron flistorg nlst m edgelist check clist pointlist po1 po2 plist2 plist2r)
  (setq clean-lst (vl-remove-if-not '(lambda (x) (and (numberp x) (> x 2))) in-lst)
        flist nil plist nil plistround nil rt nil polcolor nil hd:illegal-poly nil)
  (if (< (length clean-lst) 3)
    (progn
      (setq hd:illegal-poly T)
      (clearpreview)
    )
    (if (setq n (assoc clean-lst allhedron))
      (setq rt (cadr n) plist (caddr n) flist (last n))
      (progn
        (hedronradius clean-lst)
        (if (not rt)
          (progn
              (setq hd:illegal-poly T)
              (clearpreview)
           )
          (progn
            (setq pollist nil symlist nil symaxis nil axislist nil angle nil celist nil po 0)
            (addflist (addplist (polygonlist (car clean-lst))))
            (foreach po (cdr clean-lst)
              (addflist (addplist (alignrotate (car plist) (nth (last (assoc 0 (reverse flist))) plist) (polygonlist po))))
            )
            (setq po -1 nlst (mapcar '(lambda (x) (setq po (1+ po))) clean-lst))
            (foreach m nlst
              (setq n (nth m clean-lst)
                    lst2 (mapcar '(lambda (x) (nth x clean-lst)) (removefromlist m nlst))
                    angle (/ 360.0 n)
              )
              (if (if (equal (apply 'min lst2) (apply 'max lst2))
                    (setq a angle)
                    (if (equal n (* 2 (fix (/ n 2.0))))
                      (setq a (* 2 angle))
                      (if (equal lst2 (onlyonce lst2)) (setq nohedron 'T))
                    )
                  )
                (if (setq po (nth m flist))
                  (setq po (midpointoflist po)
                        po (if (equal po '(0 0 0) 1e-5) '(0.0 0.0 -1.0) (append po))
                        axislist (append axislist (list (list po a)))
                  )
                )
              )
            )
            (if (or nohedron (/= (length plist) (- (apply '+ clean-lst) (* 2 (length clean-lst)) -1)))
              (progn
                  (setq hd:illegal-poly T)
                  (setq flist nil rt nil plist (list nil))
                  (clearpreview)
                )
              (progn
                (setq flistorg flist flist nil)
                (mapcar 'addflist flistorg)
              )
            )
            (setq po 0)
            (while (and plist (nth po plist))
              (setq flist2 (filterlist '(lambda (n) (member po n)) flist))
              (cond
                ((< (distance (last plist) (car plist)) 0.8)
                 (setq po 1 plist '(nil) rt nil flist nil hd:illegal-poly T)
                 (set_tile "plist" "polyhedron")
                 (set_tile "flist" "Illegal")
                )
                ((= (length (setq lst2 (mapcar 'length flist2))) (length clean-lst))
                 (if (= (length lst2) (length (and_list lst2 clean-lst)))
                   (setq po (1+ po))
                   (progn
                     (setq hd:illegal-poly T)
                     (set_tile "plist" "polyhedron")
                     (set_tile "flist" "Illegal")
                     (setq po 1 rt nil plist '(nil) flist nil)
                   )
                 )
                )
                ((setq lst2 (mapcar 'length flist2)
                       lst3 clean-lst
                       edgelist (apply 'append (mapcar 'facetolines flist2))
                       edgelist (filterlist '(lambda (x) (member po x)) edgelist)
                       edgelist (filterlist '(lambda (x) (not (member (reverse x) edgelist))) edgelist)
                       edgelist (filterlist '(lambda (x) (not (member x (cdr (member x edgelist))))) edgelist)
                       edgelist (car edgelist)
                       check nil
                 )
                 nil
                )
                (edgelist
                 (foreach n lst2 (setq lst3 (removefromlist n lst3)))
                 (while (not check)
                   (setq n (car lst3)
                         po1 (car edgelist) po2 (cadr edgelist)
                         plist2 plist plist2r plistround
                         lst2 (addplist (alignrotate (nth po2 plist) (nth po1 plist) (polygonlist n)))
                         check 'T
                   )
                   (foreach p lst2
                     (setq clist (mapcar 'length (filterlist '(lambda (x) (member p x)) flist))
                           clist (append clist (list (length lst2)))
                     )
                     (if (/= (length clist) (length (and_list clist clean-lst)))
                       (setq check nil)
                     )
                   )
                   (if check
                     (addflist lst2)
                     (if (not (setq po (1+ po) plist plist2 plistround plist2r lst3 (cdr lst3)))
                       (progn
                         (setq flist (list (car flist))
                               n (length (car flist))
                               clean-lst (append (cdr clean-lst) (list (car clean-lst)))
                               po 0 check 'T
                         )
                         (while (> (length plist) n)
                           (setq plist (reverse (cdr (reverse plist)))
                                 plistround (reverse (cdr (reverse plistround)))
                           )
                         )
                       )
                     )
                   )
                 )
                )
                ('T (setq po (1+ po)))
              )
            )
          )
        )
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION addflist
;;; Description: Adds a face to the global face list (flist), avoiding
;;;              duplicates (including rotated duplicates). Also adds the face
;;;              to the cell list (celist) and propagates rotations around
;;;              symmetry axes.
;;; Parameters:
;;;   flst - List: the face as a list of vertex indices.
;;; Returns:   nil (modifies global flist, celist).
;;; Usage:     (addflist '(0 1 2))
;;; --------------------------------------------------------------------------
(defun addflist (flst / lst2 n check x po poround pox axis angle po2)
  (setq n (apply 'min flst))
  (while (/= n (car flst))
    (setq flst (append (cdr flst) (list (car flst))))
  )
  (setq n (length flst) check (member flst flist))
  (if (not check)
    (progn
      (setq lst2 flist
            flist (append flist (list flst))
            po (midpointoflist flst)
            poround (mapcar '(lambda (x) (fix (* 10000 x))) po)
            celist (append celist (list poround))
      )
      (foreach axis axislist
        (setq pox (car axis) angle (cadr axis)
              po2 (if (equal po pox 1e-5) (append pox) (hd:rot-axis po pox angle))
              po2 (mapcar '(lambda (x) (fix (* 10000 x))) po2)
        )
        (if (not (member po2 celist))
          (addflist (addplist (rotateaxislist pox angle flst)))
        )
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION rotateaxislist
;;; Description: Rotates all vertices of a face around a given axis by an angle.
;;; Parameters:
;;;   po    - List of 3 reals: the rotation axis point.
;;;   angle - Real: rotation angle in degrees.
;;;   lst   - List: face as a list of vertex indices.
;;; Returns:   List: the rotated face as a list of 3D points.
;;; Usage:     (rotateaxislist '(0 0 1) 90 '(0 1 2))
;;; --------------------------------------------------------------------------
(defun rotateaxislist (po angle lst / x)
  (mapcar '(lambda (x) (hd:rot-axis (nth x plist) po angle)) lst)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION midpointoflist
;;; Description: Computes the centroid (average point) of a face defined by
;;;              vertex indices into the global plist.
;;; Parameters:
;;;   lst - List: face as a list of vertex indices.
;;; Returns:   List of 2 or 3 reals: the centroid coordinates.
;;; Usage:     (midpointoflist '(0 1 2))
;;; --------------------------------------------------------------------------
(defun midpointoflist (lst / w z y x l)
  (setq l (if (and plist (car plist) (cddr (car plist))) '(0 1 2) '(0 1)))
  (mapcar '(lambda (w) (/ w (float (length lst))))
          (mapcar '(lambda (z) (apply '+ z))
                  (mapcar '(lambda (y)
                             (mapcar '(lambda (x) (nth y x))
                                     (mapcar '(lambda (n) (nth n plist)) lst)
                             )
                           ) l)
          )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION 2npolygon
;;; Description: Expands a face (list of vertex indices) into a list of edges
;;;              (each edge is a cons pair of adjacent vertex indices).
;;;              Optionally omits reverse edges when n is 0.5.
;;; Parameters:
;;;   lst - List: face as a list of vertex indices.
;;; Returns:   List: list of edge pairs (cons cells).
;;; Usage:     (2npolygon '(0 1 2))
;;; --------------------------------------------------------------------------
(defun 2npolygon (lst / lst2 x2 dummy)
  (setq lst2 (append lst (list (car lst))))
  (apply 'append
    (mapcar '(lambda (x)
               (setq lst2 (cdr lst2)
                     x2 (car lst2)
                     dummy (append (list (cons x x2)) (if (/= n 0.5) (list (cons x2 x)))) 
               )
             ) lst)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION triangulate
;;; Description: Subdivides each face of the current polyhedron (flist) into
;;;              triangles by inserting midpoints of edges, normalizing them
;;;              to the circumsphere. Used for geodesic dome generation.
;;; Parameters: None.
;;; Returns:   nil (modifies global plist and flist).
;;; Usage:     (triangulate)
;;; --------------------------------------------------------------------------
(defun triangulate (/ dplist dflist lst n m po x clist)
  (setq dflist
    (if (> (apply 'max (mapcar 'length flist)) 3)
      (apply 'append
        (mapcar '(lambda (lst)
                   (if (= 3 (length lst))
                     (list lst)
                     (mapcar '(lambda (n) (append n (list lst))) (facetolines lst))
                   )
                 ) flist)
      )
      (apply 'append
        (mapcar '(lambda (lst)
                   (append
                     (mapcar '(lambda (n)
                                (mapcar '(lambda (m) (if (= m n) n (list m n))) lst)
                              ) lst)
                     (list (facetolines lst))
                   )
                 ) flist)
      )
    )
    clist nil
    dflist (mapcar '(lambda (lst)
                      (mapcar '(lambda (n)
                                 (cond
                                   ((numberp n) n)
                                   ((setq x (assoc n clist)) (cadr x))
                                   ((setq x (assoc (reverse n) clist)) (cadr x))
                                   ('T
                                    (setq x (+ (length plist) (length clist))
                                          clist (append clist (list (list n x)))
                                          x x
                                    )
                                   )
                                 )
                               ) lst)
                    ) dflist)
    plist (append plist
            (mapcar '(lambda (n)
                       (setq po (midpointoflist (car n))
                             po (hd:v-scale (hd:v-unit po) (or rt 1.0))
                       )
                     ) clist)
          )
    flist dflist
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION dualize2
;;; Description: Performs a dualization (truncation) of the current polyhedron
;;;              by creating new faces at the vertices and edges. Used when
;;;              the truncation parameter is greater than 0.5.
;;; Parameters:
;;;   nn - Real: truncation parameter (between 0.5 and 1.0).
;;; Returns:   nil (modifies global dplist, dflist).
;;; Usage:     (dualize2 0.75)
;;; --------------------------------------------------------------------------
(defun dualize2 (nn / clist dflist2 face lst lst2 n po x clist2 dplist po1 po2 pon)
  (setq po 0
        dflist
        (append
          (mapcar '(lambda (face)
                     (mapcar '(lambda (n) (list face n)) (facetolines face))
                   ) flist)
          (mapcar '(lambda (n)
                     (setq lst (filterlist '(lambda (x) (member po x)) flist)
                           po (1+ po)
                           flist2 (list (car lst)) lst (cdr lst))
                     (repeat (length lst)
                       (while (not (cdr (and_list (last flist2) (car lst))))
                         (setq lst (append (cdr lst) (list (car lst))))
                       )
                       (setq flist2 (append flist2 (list (car lst))) lst (cdr lst))
                     )
                     (setq face (last flist2))
                     (apply 'append
                       (mapcar '(lambda (n)
                                  (setq lst2 (and_list n face)
                                        lst2 (list (list face lst2) (list n lst2))
                                        face n)
                                  (append lst2)
                                ) flist2)
                     )
                   ) plist)
        )
        clist nil
        dflist (mapcar '(lambda (face)
                          (mapcar '(lambda (po)
                                     (mapcar '(lambda (lst)
                                                (if (assoc (setq lst (orderface lst)) clist) nil
                                                  (setq po (mapcar '(lambda (x) (+ x 1000.0 -1000.0)) (midpointoflist lst))
                                                        clist (append clist (list (list lst po)))
                                                  )
                                                )
                                                (append lst)
                                              ) po)
                                   ) face)
                        ) dflist)
        clist2 nil
        dflist (mapcar '(lambda (face)
                          (mapcar '(lambda (po)
                                     (if (setq n (member po clist2))
                                       (- (length clist2) (length n))
                                       (setq n (length clist2)
                                             clist2 (append clist2 (list po))
                                             n n)
                                     )
                                   ) face)
                        ) dflist)
        dplist (mapcar '(lambda (po)
                          (setq po1 (last (assoc (car po) clist))
                                po2 (last (assoc (last po) clist))
                                pon (hd:plt po2 po1 nn)
                          )
                        ) clist2)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION dualize
;;; Description: Main dualization/truncation dispatcher. Calls dualize2 for
;;;              truncation values > 0.5, or performs edge/vertex truncation
;;;              for values <= 0.5. Updates global dplist and dflist.
;;; Parameters:
;;;   n - Real: truncation parameter (0.0 to 1.0).
;;; Returns:   nil (modifies global dplist, dflist).
;;; Usage:     (dualize 0.3)
;;; --------------------------------------------------------------------------
(defun dualize (n / po lst dummy face n po1 po2 pon x clist a b c)
  (if (> n 0.5)
    (dualize2 (min 1.0 (* 2.0 (- n 0.5))))
    (setq n (max 0.0 n)
          po 0
          dflist (append
                   (mapcar '2npolygon flist)
                   (mapcar '(lambda (dummy)
                              (setq lst (filterlist '(lambda (x) (member po x)) flist)
                                    lst (cdr (joinlines (mapcar '(lambda (lst)
                                                                  (while (/= (cadr lst) po)
                                                                    (setq lst (append (cdr lst) (list (car lst))))
                                                                  )
                                                                  (list (car lst) (caddr lst))
                                                                ) lst)))
                                    lst (mapcar '(lambda (lst) (cons po lst)) (reverse lst))
                                    po (1+ po))
                              (append lst)
                            ) plist)
                 )
          clist nil
          dflist (mapcar '(lambda (face)
                            (mapcar '(lambda (po)
                                       (if (setq x (assoc po clist))
                                         (cdr x)
                                         (setq x (length clist)
                                               clist (append clist (append (list (cons po x))))
                                               x x)
                                       )
                                     ) face)
                          ) dflist)
          dplist (mapcar '(lambda (po)
                            (setq po1 (nth (caar po) plist)
                                  po2 (nth (cdar po) plist)
                                  pon (hd:plt po1 po2 n)
                            )
                          ) clist)
    )
  )
  (setq dflist
    (mapcar '(lambda (lst)
               (setq a (nth (car lst) dplist)
                     b (nth (cadr lst) dplist)
                     c (nth (caddr lst) dplist)
               )
               (if (< (hd:triple-product a b c) 0.0)
                 (append lst)
                 (reverse lst)
               )
             ) dflist)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION joinlines
;;; Description: Joins a list of line segments (each a list of vertex indices)
;;;              into a single continuous polyline by matching endpoints.
;;; Parameters:
;;;   lst - List: list of segments (lists of indices).
;;; Returns:   List: the joined polyline as a list of indices.
;;; Usage:     (joinlines '((0 1) (1 2) (2 3)))
;;; --------------------------------------------------------------------------
(defun joinlines (lst / n n3 n2)
  (while (and (car lst) (cadr lst))
    (setq n (car lst) n3 (cddr lst) n2 (cadr lst))
    (setq lst
      (cond
        ((= (last n) (car n2)) (append (list (append n (cdr n2))) n3))
        ((= (car n) (car n2)) (append (list (append (reverse (cdr n)) n2)) n3))
        ((= (last n2) (car n)) (append (list (append n2 (cdr n))) n3))
        ('T (append (list n2) n3 (list (reverse n))))
      )
    )
  )
  (car lst)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION alignrotate
;;; Description: Aligns and rotates a polygon (defined in a local frame) so
;;;              that its first two vertices match two target points on the
;;;              global polyhedron, sharing an edge. Returns the transformed
;;;              vertex list in global coordinates.
;;; Parameters:
;;;   pn0, pn1 - Lists of 3 reals: the two target points on the global polyhedron.
;;;   plist    - List: the local polygon vertices to transform.
;;; Returns:   List: the transformed polygon vertices in global coordinates.
;;; Usage:     (alignrotate p1 p2 (polygonlist 4))
;;; --------------------------------------------------------------------------
(defun alignrotate (pn0 pn1 plist / po0 po1 xo yo zo xn yn zn plistn)
  (setq po0 (car plist)
        po1 (cadr plist)
        xo (hd:v-unit (hd:v-sub po1 po0))
        yo (hd:v-unit (hd:v-cross po0 po1))
        zo (hd:v-unit (hd:v-cross xo yo))
        xn (hd:v-unit (hd:v-sub pn1 pn0))
        yn (hd:v-unit (hd:v-cross pn0 pn1))
        zn (hd:v-unit (hd:v-cross xn yn))
        plistn (mapcar '(lambda (po)
                          (hd:v-add
                            (hd:v-add (hd:v-scale xn (hd:v-dot po xo))
                                      (hd:v-scale yn (hd:v-dot po yo)))
                            (hd:v-scale zn (hd:v-dot po zo))))
                        (cddr plist))
  )
  (append (list pn0 pn1) plistn)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION polygonlist
;;; Description: Generates a regular polygon with n sides, positioned in 3D
;;;              space at the correct height for the current circumradius (rt).
;;;              Results are cached in the global pollist.
;;; Parameters:
;;;   n - Integer: number of polygon sides.
;;; Returns:   List: the polygon vertices as 3D points.
;;; Usage:     (polygonlist 5)
;;; --------------------------------------------------------------------------
(defun polygonlist (n / po lst a a0 r z plist rad r-rt)
  (if (and (numberp n) (> n 2))
    (if (assoc n pollist)
      (cdr (assoc n pollist))
      (progn
        (setq lst (polygonmath n)
              a (nth 1 lst)
              a0 (/ a 2.0)
              r (nth 2 lst)
              r-rt (if (numberp rt) rt 1.0)
              z (- (sqrt (max 0.0 (- (* r-rt r-rt) (* r r)))))
        )
        (repeat (fix n)
          (setq rad (* a0 (/ pi 180.0))
                po (list (* r (cos rad)) (* r (sin rad)) z)
                a0 (+ a a0)
                plist (append plist (list po))
          )
        )
        (setq pollist (append pollist (list (cons n plist))))
        (append plist)
      )
    )
    nil
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION hedronradius
;;; Description: Calculates the circumradius (rt) of a polyhedron based on the
;;;              sequence of polygons around a vertex. Uses analytical formulas
;;;              for regular and triangular configurations, and bisection for
;;;              general cases.
;;; Parameters:
;;;   raw-lst - List: polygon side counts (e.g., '(3 3 3 nil nil)).
;;; Returns:   nil (sets global rt).
;;; Usage:     (hedronradius '(4 4 4 nil nil))
;;; --------------------------------------------------------------------------
(defun hedronradius (raw-lst / lst a r p rmin rmax blist A rz iter sum-angles)
  (setq rt nil)
  (setq lst (vl-remove-if-not '(lambda (x) (and (numberp x) (> x 2))) raw-lst))
  (if (>= (length lst) 3)
    (progn
      (setq blist (mapcar 'polygonmath lst))
      (setq sum-angles (apply '+ (mapcar 'car blist)))
      (if (< sum-angles 360.0)
        (progn
          (setq blist (mapcar '(lambda (n) (nth 3 n)) blist))
          (cond
            ((= (apply 'min lst) (apply 'max lst))
             (setq a (/ pi (float (length lst)))
                   r (/ (car blist) 2.0 (sin a)))
            )
            ((= 3 (length lst))
             (setq p (/ (apply '+ blist) 2.0)
                   A (sqrt (max 0.0 (* p (apply '* (mapcar '(lambda (n) (- p n)) blist))))))
             (if (> A 1e-9)
               (setq r (/ (apply '* blist) 4.0 A))
               (setq r 1.0)
             )
            )
            ('T
             (setq r (apply 'max blist) rmax 10.0 rmin (/ (apply 'max blist) 2.0) iter 0)
             (while (< iter 60)
               (setq iter (1+ iter)
                     r (sqrt (* rmin rmax))
                     a (apply '+ (mapcar '(lambda (n) (hd:acos (- 1.0 (/ (* n n) (* 2.0 r r))))) blist)))
               (if (equal a 360.0 1e-4)
                 (setq iter 100)
                 (if (> a 360.0)
                   (setq rmin r)
                   (setq rmax r)
                 )
               )
             )
            )
          )
          (if (and (numberp r) (> r 0.0) (<= r 10.0))
            (progn
              (setq rz (sqrt (max 0.0 (- 1.0 (* r r)))))
              (setq rt (if (> rz 1e-9) (/ (+ (* r r) (* rz rz)) 2.0 rz) 1.0))
            )
            (setq rt nil)
          )
        )
        (setq rt nil)
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION addplist
;;; Description: Adds a point to the global vertex list (plist), avoiding
;;;              duplicates by rounding coordinates to 2 decimal places.
;;;              Returns the index of the point.
;;; Parameters:
;;;   po - List of 3 reals: the point to add, or a list of points.
;;; Returns:   Integer or list of integers: the index(es) of the point(s).
;;; Usage:     (addplist '(1.0 2.0 3.0))
;;; --------------------------------------------------------------------------
(defun addplist (po / n po2)
  (if (listp (car po))
    (mapcar 'addplist po)
    (if (setq n (member (setq po2 (mapcar '(lambda (n) (fix (+ 0.5 (* 100.0 n)))) po)) plistround))
      (- (length plist) (length n))
      (setq n (length plist)
            plist (append plist (list po))
            plistround (append plistround (list po2))
            n n)
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION polygonmath
;;; Description: Returns mathematical properties of a regular polygon with n
;;;              sides: interior angle, central angle, circumradius, edge
;;;              length, and chord length for the second-nearest vertex.
;;; Parameters:
;;;   n - Integer: number of polygon sides.
;;; Returns:   List of 5 reals: (interior-angle central-angle radius edge chord).
;;; Usage:     (polygonmath 5)
;;; --------------------------------------------------------------------------
(defun polygonmath (n / po angle cangle radius beam2 beam3 rad1 rad2)
  (if (and (numberp n) (> n 2))
    (progn
      (setq angle (/ (* 180.0 (- n 2.0)) (float n))
            cangle (/ 360.0 (float n))
            radius (/ 1.0 (* 2.0 (sin (/ (* cangle (/ pi 180.0)) 2.0))))
            rad1 (* (- 180.0 angle) (/ pi 180.0))
            po (list (+ 1.0 (cos rad1)) (sin rad1) 0.0)
            beam2 (hd:v-len po)
            rad2 (* (- 360.0 (* 2.0 angle)) (/ pi 180.0))
            beam3 (if (= n 3) 0.0 (hd:v-len (hd:v-add po (list (cos rad2) (sin rad2) 0.0))))
      )
      (list angle cangle radius beam2 beam3)
    )
    '(0.0 0.0 0.0 0.0 0.0)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION facetolines
;;; Description: Converts a face (list of vertex indices) into a list of
;;;              edges (each edge is a list of two adjacent indices).
;;; Parameters:
;;;   lst - List: face as a list of vertex indices.
;;; Returns:   List: list of edges (each a list of two indices).
;;; Usage:     (facetolines '(0 1 2))
;;; --------------------------------------------------------------------------
(defun facetolines (lst / count lst2)
  (setq count 0 lst2 (append lst (list (car lst))))
  (mapcar '(lambda (n)
             (setq count (1+ count))
             (list n (nth count lst2))
           ) lst)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION removefromlist
;;; Description: Removes the first occurrence of nn from list lsst.
;;; Parameters:
;;;   nn  - The element to remove.
;;;   lsst- List: the original list.
;;; Returns:   List: the list without the first occurrence of nn.
;;; Usage:     (removefromlist 3 '(1 2 3 4))
;;; --------------------------------------------------------------------------
(defun removefromlist (nn lsst / x)
  (apply 'append (mapcar '(lambda (x) (if (equal nn x) (setq nn nil) (list x))) lsst))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION filterlist
;;; Description: Returns a new list containing only the elements for which the
;;;              predicate function funktio returns true.
;;; Parameters:
;;;   funktio - Symbol: the predicate function (e.g., 'eval, 'numberp).
;;;   lts     - List: the list to filter.
;;; Returns:   List: the filtered list.
;;; Usage:     (filterlist 'numberp '(1 "a" 2 "b" 3))
;;; --------------------------------------------------------------------------
(defun filterlist (funktio lts / xx)
  (apply 'append (mapcar '(lambda (xx) (if ((eval funktio) xx) (list xx))) lts))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION onlyonce
;;; Description: Returns a list of unique elements from lst (removes all
;;;              duplicates).
;;; Parameters:
;;;   lst - List: the input list.
;;; Returns:   List: the list of unique elements.
;;; Usage:     (onlyonce '(1 2 2 3 3 3))
;;; --------------------------------------------------------------------------
(defun onlyonce (lst)
  (apply 'append (mapcar '(lambda (x) (if (member x (setq lst (cdr lst))) nil (list x))) lst))
)

;;;---------------------------------------------------------------------------
;;; FUNCTION orderface
;;; Description: Rotates a face (list of indices) so that it starts with the
;;;              smallest index. Used for consistent face comparison.
;;; Parameters:
;;;   lst - List: face as a list of vertex indices.
;;; Returns:   List: the rotated face.
;;; Usage:     (orderface '(2 3 0 1))
;;; --------------------------------------------------------------------------
(defun orderface (lst / a)
  (setq a (apply 'min lst))
  (while (/= (car lst) a)
    (setq lst (append (cdr lst) (list (car lst))))
  )
  (append lst)
)

;;;---------------------------------------------------------------------------
;;; FUNCTION and_list
;;; Description: Computes the intersection of two lists (elements common to
;;;              both), preserving the order of the first list.
;;; Parameters:
;;;   lst, lst2 - Lists to intersect.
;;; Returns:   List: the intersection of the two lists.
;;; Usage:     (and_list '(1 2 3) '(2 3 4))
;;; --------------------------------------------------------------------------
(defun and_list (lst lst2 / n)
  (cond
    ((equal lst lst2) (append lst))
    ((not lst) nil)
    ((not lst2) nil)
    ((not (member (car lst2) lst)) (and_list lst (cdr lst2)))
    ((not (member (setq n (car lst)) lst2)) (and_list (cdr lst) (cdr lst2)))
    ((equal n (car lst2)) (append (list n) (and_list (cdr lst) (cdr lst2))))
    ('T (append (list n) (and_list (cdr lst) (removefromlist n lst2))))
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION drawsolid
;;; Description: Renders the polyhedron as a 3D solid using CSG operations.
;;;              Creates a bounding box, then slices it with each face plane
;;;              to approximate the polyhedron shape. Assigns colors by face
;;;              side count if a color palette is defined.
;;; Parameters:
;;;   plist - List of 3D points: the polyhedron vertices.
;;;   flist - List of faces: each face is a list of vertex indices.
;;; Returns:   nil
;;; Usage:     (drawsolid plist flist)
;;; --------------------------------------------------------------------------
(defun drawsolid (plist flist / po face x y p1 p2 p3)
  (if (and plist flist (not (member nil plist)))
    (progn
      (setq po (mapcar '(lambda (y)
                          (mapcar '(lambda (x) (apply y (mapcar x plist)))
                                  '(car cadr last)
                          )
                        )
                       '(min max)
               )
      )
      (command "._BOX" "_NON" (car po) "_NON" (last po))
      (foreach face flist
        (if auto-layer
          (hd:get-or-create-layer (length face))
          (if (and polcolor (eval (polcolorname (length face))))
            (setvar "CECOLOR" (eval (polcolorname (length face))))
          )
        )
        (setq po (mapcar '(lambda (x) (nth x face)) (list 0 (fix (/ (length face) 2)) (1- (length face))))
              po (mapcar '(lambda (x) (nth x plist)) po)
        )
        (if (and (nth 0 po) (nth 1 po) (nth 2 po))
          (progn
            (setq p1 (nth 0 po) p2 (nth 1 po) p3 (nth 2 po))
            (command "._SLICE" (entlast) "" "_3" "_NON" p1 "_NON" p2 "_NON" p3 "_NON" cepoint)
          )
        )
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION drawmesh
;;; Description: Renders the polyhedron as a polyface mesh (legacy AutoCAD
;;;              mesh object) using the PFACE command. Each face is created
;;;              as a separate polyface.
;;; Parameters:
;;;   plist - List of 3D points: the polyhedron vertices.
;;;   flist - List of faces: each face is a list of vertex indices.
;;; Returns:   nil
;;; Usage:     (drawmesh plist flist)
;;; --------------------------------------------------------------------------
(defun drawmesh (plist flist / po face)
  (if (and plist flist (not (member nil plist)))
    (progn
      (foreach face flist
        (if auto-layer
          (hd:get-or-create-layer (length face))
        )
        (command "._PFACE")
        (foreach po plist
          (command "_NON" (trans po 1 0))
        )
        (command "")
        (if (not auto-layer)
          (if polcolor
            (command "._COLOR" (eval (polcolorname (length face))))
          )
        )
        (foreach po face
          (command (1+ po))
        )
        (command "")
        (command "")
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION drawsubdmesh
;;; Description: Renders the polyhedron as a Sub-D mesh (modern AutoCAD mesh
;;;              object) using the MESH command. Supports triangular and
;;;              quadrilateral faces directly; higher-order faces fall back
;;;              to polyface mesh rendering.
;;; Parameters:
;;;   plist - List of 3D points: the polyhedron vertices.
;;;   flist - List of faces: each face is a list of vertex indices.
;;; Returns:   nil
;;; Usage:     (drawsubdmesh plist flist)
;;; --------------------------------------------------------------------------
(defun drawsubdmesh (plist flist / face pts p1 p2 p3 p4)
  (if (and plist flist (not (member nil plist)))
    (progn
      (foreach face flist
        (if auto-layer
          (hd:get-or-create-layer (length face))
        )
        (setq pts (mapcar '(lambda (idx) (trans (nth idx plist) 1 0)) face))
        (cond
          ((= (length pts) 3)
           (command "._MESH" "_3" "_NON" (car pts) "_NON" (cadr pts) "_NON" (caddr pts) "_NON" (caddr pts))
          )
          ((= (length pts) 4)
           (command "._MESH" "_4" "_NON" (car pts) "_NON" (cadr pts) "_NON" (caddr pts) "_NON" (cadddr pts))
          )
          ('T
           (drawmesh plist (list face))
          )
        )
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION drawwireframe
;;; Description: Renders the polyhedron as a 3D wireframe using closed 3D
;;;              polylines for each face edge loop.
;;; Parameters:
;;;   plist - List of 3D points: the polyhedron vertices.
;;;   flist - List of faces: each face is a list of vertex indices.
;;; Returns:   nil
;;; Usage:     (drawwireframe plist flist)
;;; --------------------------------------------------------------------------
(defun drawwireframe (plist flist / face idx)
  (if (and plist flist (not (member nil plist)))
    (progn
      (foreach face flist
        (if auto-layer
          (hd:get-or-create-layer (length face))
          (if (and polcolor (eval (polcolorname (length face))))
            (setvar "CECOLOR" (eval (polcolorname (length face))))
          )
        )
        (command "._3DPOLY")
        (foreach idx face
          (command "_NON" (trans (nth idx plist) 1 0))
        )
        (command "_C")
      )
    )
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION StringWrap
;;; Description: Wraps a string into multiple lines of a specified maximum
;;;              length, breaking at spaces where possible. (Based on Lee Mac,
;;;              2011, modified.)
;;; Parameters:
;;;   str - String: the text to wrap.
;;;   len - Integer: maximum line length.
;;; Returns:   List of strings: the wrapped lines.
;;; Usage:     (StringWrap "This is a long text..." 40)
;;; --------------------------------------------------------------------------
(defun StringWrap (str len / pos)
  (if (< len (strlen str))
    (cons
      (substr str 1
        (cond
          ((setq pos (vl-string-position 32 (substr str 1 len) nil t)))
          ((setq pos (1- len)) len)
        )
      )
      (StringWrap (substr str (+ 2 pos)) len)
    )
    (list str)
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION read-lines
;;; Description: Reads all lines from a text file and returns them as a list
;;;              of strings. Displays an alert if the file is not found.
;;;              (Based on ChatGPT, 2024.)
;;; Parameters:
;;;   filepath - String: name or path of the text file to read.
;;; Returns:   List of strings: each line of the file, or nil on failure.
;;; Usage:     (read-lines "ArkZ3DHedron.txt")
;;; --------------------------------------------------------------------------
(defun read-lines (filepath / file lines line)
  (setq lines nil)
  (if (and (setq filepath (findfile filepath))
           (setq file (open filepath "r")))
    (progn
      (while (setq line (read-line file))
        (setq lines (append lines (list line)))
      )
      (close file)
    )
    (progn
      (alert (strcat "File not found: " filepath))
      nil
    )
  )
  lines
)

;;;---------------------------------------------------------------------------
;;; FUNCTION process-text-for-display
;;; Description: Processes a list of text lines for display in a list_box,
;;;              wrapping each line to the specified maximum width.
;;; Parameters:
;;;   lines     - List of strings: the text lines.
;;;   max-width - Integer: maximum character width per line.
;;; Returns:   List of strings: the wrapped text lines ready for display.
;;; Usage:     (process-text-for-display my-lines 60)
;;; --------------------------------------------------------------------------
(defun process-text-for-display (lines max-width)
  (if lines
    (apply 'append 
      (mapcar '(lambda (line) (StringWrap line max-width)) lines)
    )
    (list "No information available.")
  )
)

;;;---------------------------------------------------------------------------
;;; FUNCTION ArkZ3DHedron_Help
;;; Description: Displays the help dialog (ArkZ3DHedron_Help) loading text
;;;              from "ArkZ3DHedron.txt" and showing program information 
;;;              and the Ark-Z logo. Alerts the user if the help text 
;;;              file or the DCL dialog cannot be found.
;;; Parameters: None.
;;; Returns:   nil
;;; Usage:     (ArkZ3DHedron_Help)
;;; --------------------------------------------------------------------------
(defun ArkZ3DHedron_Help (/ dcl_id lines display-text)
  ;; Check if ArkZ3DHedron.txt exists
  (if (not (findfile "ArkZ3DHedron.txt"))
    (progn
      (alert "The file ArkZ3DHedron.txt was not found.\n\nThe help program will not be displayed.")
      (princ)  ;; Return silently without opening the DCL
    )
    (progn
      ;; File exists, proceed with opening the dialog
      (if (and (setq dcl_id (load_dialog "ArkZ3DHedron.dcl"))
               (new_dialog "ArkZ3DHedron_Help" dcl_id))
        (progn
          ;; Load and display the help text from the file
          (if (setq lines (read-lines "ArkZ3DHedron.txt"))
            (progn
              (setq display-text (process-text-for-display lines 60))
              (start_list "lstAbout")
              (foreach line display-text
                (add_list line)
              )
              (end_list)
            )
            ;; If the file cannot be read (even though it exists)
            (progn
              (start_list "lstAbout")
              (foreach line '("Error reading the help file." 
                             "Check if the file is corrupted."
                             ""
                             "Contact technical support.")
                (add_list line)
              )
              (end_list)
            )
          )
          
          ;; Display logo
          (3DH_ShowSld "#img_logo" "ArkZ3DHedron" "ArkZLogo" -2)
          
          ;; Fill in program data
          (setq reg1 "ARK-Z ARQUITETURA")
          (setq reg2 "Applications for AutoCAD 2013 - 2026")
          (setq reg3 "License GNU GPLv3 © 2026 Ezequiel M Rezende")
          (setq reg4 "https://em-rezende.github.io/")
          (setq regdat (strcat reg1 "\n" reg2 "\n" reg3 "\n" reg4))
          (set_tile "reg_dat" regdat)
		  
          ;; Set OK button action
          (action_tile "btnOK" "(done_dialog 1)")
          
          ;; Start the dialog
          (start_dialog)
          (unload_dialog dcl_id)
        )
        (alert "Error loading help dialog.\nCheck the file ArkZ3DHedron.dcl.")
      )
    )
  )
  (princ)
)

(princ "\nArkZ3DHedron v3.5 loaded successfully! Type 'ArkZ3DHedron' to run.")
(princ)
