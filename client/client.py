import argparse
import asyncio
import time
import requests
import aiohttp

from utils import log_results, timestamp


def run_sync(target, rate, output_file, duration):
    """Synchronous client for low request rates (e.g. 10/s)."""
    times = []
    errors = 0
    interval = 1.0 / rate
    total_requests = int(rate * duration)

    print(f"[SYNC] Sending {rate} requests/sec for {duration} seconds...")

    for i in range(total_requests):
        start = time.perf_counter()
        try:
            r = requests.get(target, timeout=2)
            r.raise_for_status()
            elapsed = time.perf_counter() - start
            times.append(elapsed)
        except Exception:
            errors += 1

        # Print simple progress each second
        if (i + 1) % rate == 0:
            print(f"[{(i + 1)//rate}s] sent={i+1} ok={len(times)} failed={errors}")

        time.sleep(interval)

    log_results(times, output_file, errors)
    print(f"[DONE] Finished at {timestamp()}")


async def run_async(target, rate, output_file, duration):
    """Asynchronous client for high request rates (e.g. 10,000/s)."""
    times = []
    errors = 0
    total_requests = int(rate * duration)

    print(f"[ASYNC] Sending {rate} requests/sec for {duration} seconds...")

    async def fetch(session, idx):
        nonlocal errors
        start = time.perf_counter()
        try:
            async with session.get(target, timeout=2) as resp:
                if resp.status != 200:
                    errors += 1
                    return
                elapsed = time.perf_counter() - start
                times.append(elapsed)
        except Exception:
            errors += 1

        if (idx + 1) % rate == 0:
            print(f"[{(idx + 1)//rate}s] sent={idx+1} ok={len(times)} failed={errors}")

    async with aiohttp.ClientSession() as session:
        tasks = []
        for i in range(total_requests):
            tasks.append(fetch(session, i))
            # throttle launch speed
            await asyncio.sleep(1.0 / rate)

        await asyncio.gather(*tasks)

    log_results(times, output_file, errors)
    print(f"[DONE] Finished at {timestamp()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Benchmark client for Docker/Kubernetes service.")
    parser.add_argument("--target", type=str, required=True, help="Target URL (e.g. http://127.0.0.1:5000)")
    parser.add_argument("--rate", type=int, required=True, help="Requests per second (e.g. 10 or 10000)")
    parser.add_argument("--duration", type=int, default=5, help="Duration of test in seconds")
    parser.add_argument("--output", type=str, required=True, help="Output file path (e.g. results/docker_response_10)")
    parser.add_argument("--mode", type=str, choices=["sync", "async"], default="sync", help="Client mode: sync (low rate) or async (high rate)")

    args = parser.parse_args()

    if args.mode == "sync":
        run_sync(args.target, args.rate, args.output, args.duration)
    else:
        asyncio.run(run_async(args.target, args.rate, args.output, args.duration))
