import os
import statistics
import time

def log_results(times, output_file, errors=0):
    """
    Write response times and summary statistics to a file.
    """
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    with open(output_file, "w") as f:
        for t in times:
            f.write(f"{t:.6f}\n")

        f.write("\n=== Summary ===\n")
        if times:
            avg = statistics.mean(times)
            median = statistics.median(times)
            t_min = min(times)
            t_max = max(times)

            f.write(f"Total requests: {len(times) + errors}\n")
            f.write(f"Successful requests: {len(times)}\n")
            f.write(f"Failed requests: {errors}\n")
            f.write(f"Average response time: {avg:.6f} seconds\n")
            f.write(f"Median response time: {median:.6f} seconds\n")
            f.write(f"Min response time: {t_min:.6f} seconds\n")
            f.write(f"Max response time: {t_max:.6f} seconds\n")
        else:
            f.write("No successful requests recorded.\n")

def timestamp():
    """Return current timestamp string for debugging/logging."""
    return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
