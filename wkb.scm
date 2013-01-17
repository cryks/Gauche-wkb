(define-module wkb
  (use binary.io)
  (use gauche.generator)
  (use gauche.parameter)
  (use gauche.vport)
  (export
    read-hex-string
    open-input-hex-string
    make-wkb-reader
    ))

(select-module wkb)

(define (read-hex-string :optional (iport (current-input-port)))
  (glet* ([higher (read-char iport)]
          [lower (read-char iport)])
    (string->number (string higher lower) 16)))

(define (open-input-hex-string str)
  (make <virtual-input-port> :getb (cute read-hex-string (open-input-string str))))

(define (make-wkb-reader :optional (iport (current-input-port)))
  (generate
    (^[yield]
      (with-input-from-port iport
        (^[]
          (define (read-wkb-endian)
            (ecase (read-byte)
              [(0) 'big-endian]
              [(1) 'little-endian]))
          (define (read-wkb-points len)
            (let loop ([remain len]
                       [ret '()])
              (if (zero? remain)
                (reverse ret)
                (loop (- remain 1) (cons (cons (read-f64) (read-f64)) ret)))))
          (define (parse)
            (parameterize ([default-endian (read-wkb-endian)])
              (ecase (read-u32)
                [(1) ; WKB_TYPE_POINT
                 (yield `(POINT ,@(read-wkb-points 1)))]
                [(2) ; WKB_TYPE_LINESTRING
                 (yield `(LINESTRING ,@(read-wkb-points (read-u32))))]
                [(3) ; WKB_TYPE_POLYGON
                 (yield `(POLYGON ,@(let loop ([i (read-u32)]
                                               [pret '()])
                                      (if (zero? i)
                                        (reverse pret)
                                        (loop (- i 1) (cons (read-wkb-points (read-u32)) pret))))))]
                [(4 5 6 7) ; WKB_TYPE_MULTI*, WKB_TYPE_GEOMETRYCOLLECTION
                 (dotimes [i (read-u32)] (parse))])))

          (parse))))))
