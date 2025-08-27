import os
import time


def log_results(times, output_file):
    """Write all response times and average to file."""
    os.makedirs(os.path.dirname(output_file), exist_ok=True)  
    with open(output_file, "w") as f:
        for t in times:
            f.write(f"{t:.6f}\n")
        avg = calculate_average(times)
        f.write(f"\nAverage response time: {avg:.6f} seconds\n")
    print(f"[+] Results written to {output_file}")


def calculate_average(times):
    """Compute average response time."""
    return sum(times) / len(times) if times else 0


def record_time(func):
    """Decorator: measure execution time of a request function."""
    def wrapper(*args, **kwargs):
        t0 = time.time()
        result = func(*args, **kwargs)
        t1 = time.time()
        return result, (t1 - t0)
    return wrapper
