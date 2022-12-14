(ns day05.core
  (:gen-class))

(require '[clojure.string :as str])

(defn parse-stacks [lines]
  (let [ls (drop-last lines)
        n (/ (+ (count (first ls)) 1) 4)]
    (mapv
      (fn [i] (mapcat
        (fn [l] (let [c (nth l (+ (* i 4) 1))]
          (if (= c \ ) [] [c])))
        ls))
      (range n))))

(defn parse-int [x]
  (Integer/parseInt x))

(defn parse-inst [line]
  (map parse-int (rest (re-matches #"move (\d+) from (\d+) to (\d+)" line))))

(defn parse-insts [lines]
  (map parse-inst lines))

(defn parse-input [raw]
  (let [[raw-stacks raw-insts] (map (fn [s] (str/split s #"\n")) (str/split raw #"\n\n"))
        stacks (parse-stacks raw-stacks)
        insts (parse-insts raw-insts)]
    [stacks insts]))

(defn perform-inst [order stacks [n from to]]
  (let [i (- from 1)
        j (- to 1)]
    (reduce (fn [x f] (f x)) stacks
      [(fn [s] (update s j (fn [stack] (concat (order (take n (nth stacks i))) stack))))
       (fn [s] (update s i (fn [stack] (drop n stack))))])))

(defn perform-insts [order stacks insts]
  (reduce (partial perform-inst order) stacks insts))

(defn tops [stacks]
  (str/join (map first stacks)))

(defn -main [& args]
  (let [raw (slurp "resources/input.txt")
        [stacks insts] (parse-input raw)
        part1 (tops (perform-insts reverse stacks insts))
        part2 (tops (perform-insts identity stacks insts))]
    (printf "Part 1: %s%n" part1)
    (printf "Part 2: %s%n" part2)))
