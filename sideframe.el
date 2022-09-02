;;; sideframe.el --- Side frame -*- lexical-binding: t -*-

;; Copyright (C) 2022 Nicolas P. Rougier

;; Maintainer: Nicolas P. Rougier <Nicolas.Rougier@inria.fr>
;; URL: https://github.com/rougier/sideframe
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; Sideframe is a package for creating sideframes that are glued to another
;; parent frame. This can be used to display a menu or a dashboard for example.
;; If you want to maximize a frame that has sideframes, use the
;; `sideframe-toggle-maximized` function that computes the size properly.
;;
;;
;; Usage example:
;;
;; (sideframe-make 'left 32)
;; (sideframe-make 'right 32)
;; (sideframe-toggle-maximized)
;;
;; If you're using a theme that has both dark and light modes, you can also
;; assign a different mode to the side frame (here with nano theme):
;;
;; (sideframe-make 'left 32 'dark `((foreground-color . ,nano-dark-foreground)
;;                                  (background-color . ,nano-dark-background)))
;;
;;
;;; NEWS:
;;
;; Version 0.1
;; - First version
;;
;;; Code
(require 'frame)


(defgroup sideframe nil
  "Sideframe"
  :group 'convenience)
  
(defcustom sideframe-default-side 'left
  "Default side position"
  :type '(radio (const :tag "Left"   left)
                (const :tag "Right"  right)
                (const :tag "Top"    top)
                (const :tag "Bottom" bottom))
  :group 'sideframe)

(defcustom sideframe-default-mode 'dark
  "Default mode"
  :type '(radio (const :tag "Light" light)
                (const :tag "Dark"  dark))
  :group 'sideframe)

(defcustom sideframe-default-size 32
  "Default size "
  :type 'natnum
  :group 'sideframe)


(defun sideframe--update (&optional frame)
  "Update size and position of FRAME according its maximized state and sideframes."
  
  (interactive)
  (let* ((screen-width (nth 2 (frame-monitor-geometry)))
         (screen-height (nth 3 (frame-monitor-geometry)))
         (frame (or frame (selected-frame)))
         (border-size (frame-parameter frame 'internal-border-width))
         (frame-maximized (frame-parameter frame 'frame-maximized))
         (frame-width) (frame-height) (frame-x)  (frame-y)
         (frame-left (frame-parameter frame 'sideframe-left))
         (frame-left (if (and (framep frame-left) (frame-live-p frame-left)) frame-left))
         (frame-right (frame-parameter frame 'sideframe-right))
         (frame-right (if (and (framep frame-right) (frame-live-p frame-right)) frame-right))
         (frame-top (frame-parameter frame 'sideframe-top))
         (frame-top (if (and (framep frame-top) (frame-live-p frame-top)) frame-top))
         (frame-bottom (frame-parameter frame 'sideframe-bottom))
         (frame-bottom (if (and (framep frame-bottom) (frame-live-p frame-bottom)) frame-bottom)))

    (if frame-maximized
        (progn
          (setq frame-width (- screen-width (* 2 border-size))
                frame-height (- screen-height (* 2 border-size))
                frame-x 0
                frame-y 0)
          (when frame-left
            (setq frame-width (- frame-width (frame-pixel-width frame-left)))
            (setq frame-x (+ frame-x (frame-pixel-width frame-left))))
          (when frame-right
            (setq frame-width (- frame-width (frame-pixel-width frame-right))))
          (when frame-top
            (setq frame-height (- frame-height (frame-pixel-height frame-top)))
            (setq frame-y (+ frame-y (frame-pixel-height frame-top))))
          (when frame-bottom
            (setq frame-height (- frame-height (frame-pixel-width frame-bottom))))
          (set-frame-position frame frame-x frame-y)
          (set-frame-size frame frame-width frame-height t))
      (progn
        (setq frame-width (frame-pixel-width frame)
              frame-height (frame-pixel-height frame)
              frame-x (car (frame-position frame))
              frame-y (cdr (frame-position frame)))))

    (when frame-left
      (modify-frame-parameters frame-left `((top . 0)
                                            (left . ,(* -1 (frame-pixel-width frame))))))
    (when frame-right
      (modify-frame-parameters frame-right `((top . 0)
                                             (left . ,(frame-pixel-width frame)))))
    (when frame-top
      (modify-frame-parameters frame-top `((top . ,(* -1 (frame-pixel-width frame)))
                                           (left . 0))))
    (when frame-bottom
      (modify-frame-parameters frame-bottom `((top . ,(frame-pixel-width frame))
                                              (left . 0))))))


(defun sideframe-toggle-maximized ( )
  "Toggle the maximized state of a frame that has zero, one or
several sideframes."
  
  (interactive)
  (let* ((screen-width (nth 2 (frame-monitor-geometry)))
         (screen-height (nth 3 (frame-monitor-geometry)))
         (frame (selected-frame))
         (frame (or (frame-parameter frame 'parent-frame) frame))
         (frame-maximized (frame-parameter frame 'frame-maximized))
         (border-size (frame-parameter frame 'internal-border-width))
         (frame-width (- screen-width (* 2 border-size)))
         (frame-height (- screen-height (* 2 border-size)))
         (frame-x 0)
         (frame-y 0))
    (if frame-maximized
        (progn
          (set-frame-parameter frame 'frame-maximized nil)
          (setq frame-x (frame-parameter frame 'frame-x)
                frame-y (frame-parameter frame 'frame-y)
                frame-width (- (frame-parameter frame 'frame-width)
                               (* 2 border-size))
                frame-height (- (frame-parameter frame 'frame-height)
                                (* 2 border-size))))
      (progn
        (set-frame-parameter frame 'frame-maximized t)
        (set-frame-parameter frame 'frame-width (frame-pixel-width frame))
        (set-frame-parameter frame 'frame-height (frame-pixel-height frame))
        (set-frame-parameter frame 'frame-x (car (frame-position frame)))
        (set-frame-parameter frame 'frame-y (cdr (frame-position frame)))))
    (set-frame-position frame frame-x frame-y)
    (set-frame-size frame frame-width frame-height t)
    (sideframe--update)))



(defun sideframe-make (&optional side size mode &rest parameters)
  "Create a fixed size frame on given SIDE (left, right, top or bottom) with given MODE and SIZE.

Optional argument PARAMETERS is an alist of frame parameters for
the new frame. Each element of PARAMETERS should have the
form (NAME . VALUE).

NOTE: Right and bottom configuration require a dynamic update of their positions
      when the parent frame is resized. Unfortunately, there is no frame resize
      hook and the update is then ran whenever the parent frame first window is
      changed. This is not perfect since a frame can be resized without
      modifying the first window configuration or the first window may
      eventually be deleted. In such cases, the position might become wrong. To
      force updating, user can call again the sideframe-make function, this will
      update position."

  (interactive
   (let* ((completion-ignore-case  t))
     (list (intern (completing-read "Side (default left): "
                                    '(left right top bottom) nil t ""))
           (read-number "Size: " sideframe-default-size)
           (intern (completing-read "Mode (default light): "
                            '(light dark) nil t "")))))

  (let* ((side (if (memq side '(left right top bottom))
                   side
                 sideframe-default-size))
         (mode (if (memq mode '(light dark))
                   mode
                 sideframe-default-mode))
         (size (if (> size 0)
                   size
                 sideframe-default-size))
         (parent-frame (window-frame))
         (parent-window (frame-first-window parent-frame))
         (parent-width (frame-pixel-width))
         (parent-height (frame-pixel-height))
         (saved-background-mode frame-background-mode)
         (child-width (or (cdr (assoc 'width parameters))
                          size))
         (child-height (or (cdr (assoc 'height parameters))
                           size))
         (child-frame (cond ((eq side 'right)
                             (frame-parameter parent-frame 'sideframe-right))
                            ((eq side 'top)
                             (frame-parameter parent-frame 'sideframe-top))
                            ((eq side 'bottom)
                             (frame-parameter parent-frame 'sideframe-bottom))
                            (t ;; left
                             (frame-parameter parent-frame 'sideframe-left))))
         (child-background-mode (cdr (assoc 'background-mode parameters)))
         (size-position '()))

    (when mode
      (add-to-list 'parameters `(background-mode . ,mode)))

    (if (or (not (framep child-frame)) (not (frame-live-p child-frame)))
        (progn
          (setq frame-background-mode child-background-mode)
          (setq child-frame (make-frame (append parameters
                                                `((parent-frame . ,parent-frame)
                                                  (user-position . t)
                                                  (user-size . t)
                                                  (unsplittable . t)
                                                  (undecorated . nil)
                                                  (desktop-dont-save . t)
                                                  (delete-before ,parent-frame)
                                                  (no-other-frame . nil)
                                                  (pixelwise . t)
                                                  (visibility . nil))))))
      (progn
        (setq child-width (or (cdr (assoc 'width parameters))
                              (frame-parameter child-frame 'width)
                              32)
              child-height (or (frame-parameter child-frame 'height)
                               (cdr (assoc 'height parameters))
                               8))))
        
    (cond ((eq side 'right)
           (set-frame-parameter parent-frame 'sideframe-right child-frame)
           (setq size-position `((height . 1.0)
                                 (width . ,child-width)
                                 (min-width . ,child-width)
                                 (keep-ratio . (height-only . nil))
                                 (top . 0)
                                 (left . ,parent-width))))
          ((eq side 'top)
           (set-frame-parameter parent-frame 'sideframe-top child-frame)
           (setq size-position `((height . ,child-height)
                                 (min-height . ,child-height)
                                 (width . 1.0)
                                 (keep-ratio . (width-only . nil))
                                 (top . ,(* -1 parent-height))
                                 (left . 0))))
          ((eq side 'bottom)
           (set-frame-parameter parent-frame 'sideframe-bottom child-frame)
           (setq size-position `((height . ,child-height)
                                 (min-height . ,child-height)
                                 (width . 1.0)
                                 (keep-ratio . (width-only . nil))
                                 (top . ,parent-height)
                                 (left . 0))))
          (t ;; left
           (set-frame-parameter parent-frame 'sideframe-left child-frame)
           (setq size-position `((height . 1.0)
                                 (width . ,child-width)
                                 (min-width . ,child-width)
                                 (keep-ratio . (height-only . nil))
                                 (top . 0)
                                 (left . ,(* -1 parent-width))))))

    ;; We need to make the frame visible before setting size and position.
    (make-frame-visible child-frame)
    (modify-frame-parameters child-frame size-position)
    (sideframe--update)
    (select-frame child-frame)
    
    ;; This forces recomputation of faces on the child frame
    (setq frame-background-mode child-background-mode)
    (frame-set-background-mode child-frame)
    (set-foreground-color (face-foreground 'default child-frame t))
    (set-background-color (face-background 'default child-frame t))
    (set-face-background 'child-frame-border
                         (face-background 'default child-frame t)
                         child-frame)
    (setq frame-background-mode saved-background-mode)
    (frame-set-background-mode parent-frame)
      
    ;; There is no frame resize hook so we use the window configuration change
    ;; hook to update position (bottom and right positions only). Not perfect
    ;; but if the window configuration does not change too much, that will do.
    (add-hook 'window-configuration-change-hook #'sideframe--update)

    ;; Make sure background mode is set properly on child frame
    (set-frame-parameter child-frame 'background-mode child-background-mode)
                                     
    ;; Keep focus on parent frame 
    (x-focus-frame parent-frame)
    child-frame))


(provide 'sideframe)
;;; sideframe.el ends here

