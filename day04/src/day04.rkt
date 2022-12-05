#!/usr/bin/env racket
#lang racket

(define (parse-range raw)
  (map string->number (string-split raw "-")))

(define (parse-line line)
  (map parse-range (string-split line ",")))

(define (is-subrange range child)
  (match (list range child)
    [(list (list s1 e1) (list s2 e2))
        (and (<= s1 s2)
             (<= e2 e1))]))

(define (contains range x)
  (match range
    [(list s e) (and (<= s x) (<= x e))]))

(define (overlaps range1 range2)
  (match (list range1 range2)
    [(list (list s1 e1) (list s2 e2))
        (or (contains range1 s2)
            (contains range1 e2))]))

(define (line-satisfies f)
  (lambda (ranges)
    (match ranges
      [(list left right)
          (or (f left right)
              (f right left))])))

(define (count-satisfying f lines)
  (length (filter identity (map (line-satisfies f) lines))))

(let* ([lines (map parse-line (file->lines "resources/input.txt"))]
       [part1 (count-satisfying is-subrange lines)]
       [part2 (count-satisfying overlaps lines)])
  (printf "Part 1: ~a\n" part1)
  (printf "Part 2: ~a\n" part2))
