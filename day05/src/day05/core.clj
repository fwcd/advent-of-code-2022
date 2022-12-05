(ns day05.core
  (:gen-class))

(require '[clojure.string :as str])

(defn parse-stacks [lines]
  (let [ls (drop-last lines)
        n (/ (+ (count (first ls)) 1) 4)]
    (map
      (fn [i] (mapcat
        (fn [l] (let [c (nth l (+ (* i 4) 1))]
          (if (= c \ ) [] [c])))
        ls))
      (range n))))

(defn parse-insts [lines]
  (map (fn [l] (rest (re-matches #"move (\d+) from (\d+) to (\d+)" l))) lines))

(defn parse-input [raw]
  (let [[raw-stacks raw-insts] (map (fn [s] (str/split s #"\n")) (str/split raw #"\n\n"))
        stacks (parse-stacks raw-stacks)
        insts (parse-insts raw-insts)]
    [stacks insts]))

(defn -main [& args]
  (let [raw (slurp "resources/demo.txt")
        input (parse-input raw)]
    (println input)))
