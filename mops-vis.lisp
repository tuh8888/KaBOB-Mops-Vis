(asdf:load-system "KaBOB")

;; (defpackage :mops-vis
;;   (:use :cl :net-vis :KaBOB :mops)
;;   (:export :start-website :mops-to-json :initial-mop))

(in-package :KaBOB)

(defvar initial-mop (lookup-mop-by-uniprot-id 'P04637))

;(in-package :mops-vis)

(open-KaBOB)
;(enable-!-reader)
;(mopify (bio *p53*))


;;;;;;;;; JSON ;;;;;;;;;;

(defun stringify (x)
  (cond ((stringp x) x)
	((mops:mop-p x) (symbol-name (mop-name x)))
	((listp x) (format nil "~{~a~^, ~}" (mapcar #'stringify x)))
	(t (format nil "~a" x))))

(defun make-link (mop role filler)
  (net-vis:make-link :source (stringify mop)
		     :label (stringify role)
		     :target (stringify filler)))

(defun make-role-links (mop role)
  (mapcar #'(lambda (filler) (make-link mop role filler)) (role-filler mop role)))

(defun make-abstraction-links (mop)
  (mapcar #'(lambda (abstraction) (make-link mop "subClassOf" abstraction)) (mop-abstractions mop)))

(defun make-mop-links (mop)
  (append (make-abstraction-links mop)
	  (mapcan #'(lambda (role) (make-role-links mop role)) (mop-roles mop))))

(defun make-mop-node (x)
  (net-vis:make-node (stringify x)))

(defun make-filler-nodes (mop role)
  (mapcar #'make-mop-node (role-filler mop role)))

(defun make-mop-nodes (mop)
  `(,(make-mop-node mop)
    ,@(mapcar #'make-mop-node (mop-abstractions mop))
    ,@(mapcan #'(lambda (role) (make-filler-nodes mop role)) (mop-roles mop))))

(defun mops-to-json (mops)
  (net-vis:make-json-graph (mapcan #'make-mop-nodes mops) (mapcan #'make-mop-links mops)))

(defun find-node-data (node-name)
  (mops-to-json (list (lookup-mop (intern node-name :KaBOB)))))

;;; Overriding methods
(in-package :net-vis)

(defun send-initial-graph ()
  (format t "graph requested~%")
  (KaBOB::mops-to-json (list KaBOB::initial-mop)))

(defun send-node-data (node-name)
  (format t "node requested: ~a~%" node-name)
  (KaBOB::find-node-data node-name))
