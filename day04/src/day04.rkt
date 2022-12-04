#!/usr/bin/env racket
#lang racket

(define (parse-range raw)
  (map string->number (string-split raw "-")))

(define (parse-line line)
  (map parse-range (string-split line ",")))

(define (is-subrange parent child)
  (match (list parent child)
    [(list (list s1 e1) (list s2 e2))
        (and (<= s1 s2)
             (<= e2 e1))]))

(define (satisfies-part1 ranges)
  (match ranges
    [(list left right)
        (or (is-subrange left right)
            (is-subrange right left))]))

(let* ([lines (file->lines "resources/input.txt")]
       [ranges (map parse-line lines)]
       [part1 (length (filter identity (map satisfies-part1 ranges)))])
  (printf "Part 1: ~a\n" part1))
