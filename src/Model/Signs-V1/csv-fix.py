import os
from pathlib import Path

N_EVAL_SAMPLES = 2

def main() -> None:
    csvs = list(Path(".").glob("*.csv"))
    labels = [str(x).split(".")[0] for x in csvs]
    csvs = [open(x).read().strip() for x in csvs]

    os.mkdir("train-data")
    os.mkdir("eval-data")
    for (label, content) in zip(labels, csvs):
        samples = content.split("~~~")
        samples = ["\n".join(x.split("|||")) for x in samples]
        train_samples = samples[N_EVAL_SAMPLES:]
        eval_samples = samples[:N_EVAL_SAMPLES]
        os.mkdir(f"train-data/{label}")
        for (index, sample) in enumerate(train_samples):
            with open(f"train-data/{label}/{index}.csv", "w") as f:
                f.write("accX,accY,accZ,gyroX,gyroY,gyroZ\n" + sample)
        os.mkdir(f"eval-data/{label}")
        for (index, sample) in enumerate(eval_samples):
            with open(f"eval-data/{label}/{index}.csv", "w") as f:
                f.write("accX,accY,accZ,gyroX,gyroY,gyroZ\n" + sample)

if __name__ == "__main__":
    main()
