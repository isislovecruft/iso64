;; -*- mode: asm -*-
;;
;; This file is part of a Supersingular Isogeny Key Encapsulation (SIKE) over P434 for Commodore 64.
;; Copyright (c) 2020 isis lovecruft
;; See LICENSE for licensing information.
;;
;; Authors:
;; - isis agora lovecruft <isis@patternsinthevoid.net>

;; Montgomery x-coordinate elliptic curve arithmetic.
	
!cpu 6510                       ; For 6502/6510 with undocumented opcodes
!zone montgomery                ; Namespacing
	
