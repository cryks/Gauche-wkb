(add-load-path "." :relative)

(use gauche.test)
(use binary.io)
(use gauche.generator)
(use gauche.parameter)
(use wkb)

(test-start "wkb")

(test-module 'wkb)

(test-section "read-hex-string")

(with-input-from-string "00010203FEFF"
  (^[]
    (test* "read-hex-string" '(0 1 2 3 254 255) (generator->list read-hex-string))))

(with-input-from-string "00010203FEFFA"
  (^[]
    (test* "read-hex-string" '(0 1 2 3 254 255) (generator->list read-hex-string))))

(test-section "hex-string-port->binary-port")

(with-input-from-port (open-input-hex-string "00010203FEFF")
  (^[]
    (test* "read test" 0 (read-byte))
    (test* "read test" 1 (read-byte))
    (test* "read test" 2 (read-byte))
    (test* "read test" 3 (read-byte))
    (test* "read test" 254 (read-byte))
    (test* "read test" 255 (read-byte))
    (test* "read test" (eof-object) (read-byte))))

(with-input-from-port (open-input-hex-string "00010203FEFF")
  (^[]
    (parameterize ([default-endian 'little-endian])
      (test* "read test (u16)" #x0100 (read-u16))
      (test* "read test (u16)" #x0302 (read-u16))
      (test* "read test (u16)" #xfffe (read-u16))
      (test* "read test (u16)" (eof-object) (read-u16)))))

(test-section "wkb-reader")

(with-input-from-port (open-input-hex-string "01010000008D976E1283C0F33F16FBCBEEC9C30240")
  (^[]
    (test* "wkb point test"
      '([POINT (1.2345 . 2.3456)])
      (generator->list (make-wkb-reader)))))

(with-input-from-port (open-input-hex-string "01030000000200000005000000000000000000000000000000000000000000000000002440000000000000000000000000000024400000000000002440000000000000000000000000000024400000000000000000000000000000000005000000000000000000F03F000000000000F03F000000000000F03F0000000000000040000000000000004000000000000000400000000000000040000000000000F03F000000000000F03F000000000000F03F")
  (^[]
    (test* "wkb polygon test"
      '([POLYGON ((0.0 . 0.0) (10.0 . 0.0) (10.0 . 10.0) (0.0 . 10.0) (0.0 . 0.0))
                 ((1.0 . 1.0) (1.0 . 2.0) (2.0 . 2.0) (2.0 . 1.0) (1.0 . 1.0))])
      (generator->list (make-wkb-reader)))))

(with-input-from-port (open-input-hex-string "01060000000200000001030000000200000005000000000000000000000000000000000000000000000000001040000000000000000000000000000010400000000000001040000000000000000000000000000010400000000000000000000000000000000005000000000000000000F03F000000000000F03F0000000000000040000000000000F03F00000000000000400000000000000040000000000000F03F0000000000000040000000000000F03F000000000000F03F01030000000100000005000000000000000000F0BF000000000000F0BF000000000000F0BF00000000000000C000000000000000C000000000000000C000000000000000C0000000000000F0BF000000000000F0BF000000000000F0BF")
  (^[]
    (test* "wkb multi-polygon test"
      '([POLYGON ((0.0 . 0.0) (4.0 . 0.0) (4.0 . 4.0) (0.0 . 4.0) (0.0 . 0.0))
                 ((1.0 . 1.0) (2.0 . 1.0) (2.0 . 2.0) (1.0 . 2.0) (1.0 . 1.0))]
        [POLYGON ((-1.0 . -1.0) (-1.0 . -2.0) (-2.0 . -2.0) (-2.0 . -1.0) (-1.0 . -1.0))])
      (generator->list (make-wkb-reader)))))

(test-end)
