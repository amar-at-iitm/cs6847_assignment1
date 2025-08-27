import argparse
import time
import asyncio
import aiohttp
import requests
from utils import log_results, record_time


@record_time
def sync_request(target):
    """Send one synchronous request and return response."""
    r = requests.get(target)
    r.raise_for_status()
    return r


def run_sync(target, rate, output_file, duration=5):
    """Send requests synchronously at given rate (requests per second)."""
    interval = 1.0 / rate
    times = []

    print(f"[SYNC] Sending {rate} requests/sec for {duration} seconds...")
    start_time = time.time()
    while time.time() - start_time < duration:
        try:
            _, elapsed = sync_request(target)
            times.append(elapsed)
        except Exception as e:
            print(f"Request failed: {e}")
        sleep_time = interval - (time.time() - start_time) % interval
        if sleep_time > 0:
            time.sleep(sleep_time)

    log_results(times, output_file)


async def fetch(session, target, times):
    """Helper: send one async request and record time."""
    t0 = time.time()
    try:
        async with session.get(target) as resp:
            await resp.text()
    except Exception as e:
        print(f"Request failed: {e}")
    t1 = time.time()
    times.append(t1 - t0)


async def run_async(target, rate, output_file, duration=5):
    """Send requests asynchronously at high rate."""
    times = []
    total_requests = rate * duration
    print(f"[ASYNC] Sending ~{total_requests} requests at {rate}/sec...")

    async with aiohttp.ClientSession() as session:
        tasks = [fetch(session, target, times) for _ in range(total_requests)]
        await asyncio.gather(*tasks)

    log_results(times, output_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True, help="Target URL (http://IP:PORT)")
    parser.add_argument("--rate", type=int, required=True, help="Requests per second")
    parser.add_argument("--output", required=True, help="Output filename")
    parser.add_argument("--duration", type=int, default=5, help="Test duration in seconds")
    args = parser.parse_args()

    if args.rate <= 100:
        run_sync(args.target, args.rate, args.output, args.duration)
    else:
        asyncio.run(run_async(args.target, args.rate, args.output, args.duration))
