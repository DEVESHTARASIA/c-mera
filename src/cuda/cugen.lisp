(in-package :cugen)

;;nodes
(defelement cuda-funcall () (name grids blocks shared) (name &optional grids blocks shared)
  (make-instance 'cuda-funcall
		 :name (make-node name)
		 :grids (make-node grids)
		 :blocks (make-node blocks)
		 :shared (make-node shared)
		 :values '()
		 :subnodes '(name grids blocks shared)))

(defelement cuda-align () (name size) (name size)
  (make-instance 'cuda-align
		 :name (make-node name)
		 :size (make-node size)
		 :values '()
		 :subnodes '(size name)))

;;pretty
(with-pp
  (with-proxynodes (arrow-bracket comma)
    (defprettymethod :before cuda-funcall
      (if (slot-value item 'grids)
	  (progn (make-proxy name arrow-bracket)
		 (make-proxy grids comma)))
      (if (slot-value item 'shared)
	  (make-proxy blocks comma)))
    (defprettymethod :after cuda-funcall
      (if (slot-value item 'grids)
	  (progn
	    (del-proxy name)
	    (del-proxy grids)
	    (format stream ">>>")))
      (if (slot-value item 'shared)
	  (del-proxy blocks)))

    (defproxyprint :after arrow-bracket
      (format stream "<<<"))
    (defproxyprint :after comma
      (format stream ", "))))

(with-pp
  (with-proxynodes (size)
    (defprettymethod :before cuda-align
      (make-proxy size size)
      (format stream "__align__("))
    (defprettymethod :after cuda-align
      (del-proxy size))
    (defproxyprint :after size
      (format stream ") "))))

;;syntax
(prepare-handler)

(add-qualifier '__device__ '__global__ '__host__ '__shared__ '__constant__)

(defnodemacro funcall (function &rest parameter)
  (let* ((gbs nil)
	 (tmp (first parameter))
	 (cgen-node (if (and (listp function)
			     (cgen::find-handler (cg-user::cintern (format nil "~a" (first function)) 'cgen)))
			t nil)))
    (if (listp tmp)
	(if (and (or (= (length tmp) 3) (= (length tmp) 2))
		 (not (eql (first tmp) 'quote))
		 (not (cgen::find-handler (cg-user::cintern (format nil "~a" (first tmp)) 'cgen))))
	    (progn (setf gbs tmp)
		   ;(format t "handler-in-cuda-config not found ~a, ~s, ~s~%" (first tmp) (first tmp) (cg-user::cintern (format nil "~a" (first tmp)) 'cgen))
		   ;(if (cgen::find-handler (cg-user::cintern (format nil "~a" (first tmp)) 'cgen))
		   ;    (format t "FOUND~%")
		   ;    (format t "NOT-FOUND~%"))
		   (setf parameter (rest parameter)))))
    `(make-node (list 'cgen::funcall (make-node (list ,(if cgen-node function `',function) ,(first gbs)
						      ,(second gbs)
						      ,(third gbs))
						'cuda-funcall-handler) ,@parameter))))

(defnodemacro struct (name alignment &body body)
  (if (numberp alignment)
      `(make-node (list 'cgen::struct (make-node (list ',name ,alignment)
						 'cuda-align-handler) ,@body))
      `(make-node (list 'cgen::struct ',name ,@body))))
      

(in-package :cg-user)
(use-functions |cudaDeviceSynchronize|
	       |cudaMemcpy|
	       |cudaMemcpyHostToDevice|
	       |cudaMemcpyDeviceToHost|)

(use-variables |blockIdx|
	       |blockDim|
	       |threadIdx|)
