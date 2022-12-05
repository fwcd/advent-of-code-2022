(defproject day05 "0.1.0-SNAPSHOT"
  :description "Day 5 solution"
  :url "https://github.com/fwcd/advent-of-code-2022"
  :dependencies [[org.clojure/clojure "1.11.1"]]
  :main ^:skip-aot day05.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true"]}})
