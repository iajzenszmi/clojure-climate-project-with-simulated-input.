#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# install_and_run_climate_grid.sh
# Installs Java + Clojure CLI, creates a Clojure climate demo,
# and runs it.
#
# Target: Ubuntu / Debian Linux
# ============================================================

PROJECT_DIR="${HOME}/climate-grid"
CLOJURE_INSTALL_SCRIPT_URL="https://download.clojure.org/install/linux-install-1.11.1.1413.sh"
TMP_INSTALL_SCRIPT="/tmp/linux-install-clojure.sh"

echo "==> Updating apt package index"
#sudo apt-get update

echo "==> Installing prerequisites"
sudo apt-get install -y curl ca-certificates rlwrap openjdk-17-jdk

echo "==> Checking Java"
java -version

if command -v clojure >/dev/null 2>&1; then
  echo "==> Clojure CLI already appears to be installed"
else
  echo "==> Downloading official Clojure Linux install script"
  curl -fL "${CLOJURE_INSTALL_SCRIPT_URL}" -o "${TMP_INSTALL_SCRIPT}"
  chmod +x "${TMP_INSTALL_SCRIPT}"

  echo "==> Running official Clojure installer"
  sudo "${TMP_INSTALL_SCRIPT}"
fi

echo "==> Verifying Clojure CLI"
clojure -Sdescribe

echo "==> Creating project directory at ${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}/src/climate"

echo "==> Writing deps.edn"
cat > "${PROJECT_DIR}/deps.edn" <<'EOF'
{:paths ["src"]
 :aliases
 {:run {:main-opts ["-m" "climate.core"]}}}
EOF

echo "==> Writing source: src/climate/core.clj"
cat > "${PROJECT_DIR}/src/climate/core.clj" <<'EOF'
(ns climate.core)

(def grid-size 20)
(def min-temp 15.0)
(def temp-range 10.0)

(defn rand-temp []
  (+ min-temp (* temp-range (rand))))

(defn generate-grid []
  (vec
   (for [_x (range grid-size)]
     (vec
      (for [_y (range grid-size)]
        (rand-temp))))))

(defn clamp-index [i]
  (-> i
      (max 0)
      (min (dec grid-size))))

(defn cell [grid x y]
  (get-in grid [(clamp-index x) (clamp-index y)]))

(defn step [grid]
  (vec
   (for [x (range grid-size)]
     (vec
      (for [y (range grid-size)]
        (let [center (cell grid x y)
              north  (cell grid (dec x) y)
              south  (cell grid (inc x) y)
              west   (cell grid x (dec y))
              east   (cell grid x (inc y))]
          (/ (+ center north south west east) 5.0)))))))

(defn print-grid [grid]
  (doseq [row grid]
    (println
     (apply str
            (interpose " "
                       (map #(format "%5.1f" %) row))))))

(defn simulate [steps]
  (loop [grid (generate-grid)
         i 0]
    (println)
    (println "Step:" i)
    (print-grid grid)
    (when (< i steps)
      (Thread/sleep 400)
      (recur (step grid) (inc i)))))

(defn -main [& _args]
  (println "Running synthetic climate grid demo...")
  (simulate 10))
EOF

echo "==> Writing run.sh"
cat > "${PROJECT_DIR}/run.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
clojure -M:run
EOF

chmod +x "${PROJECT_DIR}/run.sh"

echo "==> Project created"
echo "==> Running demo"
cd "${PROJECT_DIR}"
./run.sh

echo
echo "Done."
echo "Project location: ${PROJECT_DIR}"
echo "Run again with:"
echo "  cd ${PROJECT_DIR} && ./run.sh"
