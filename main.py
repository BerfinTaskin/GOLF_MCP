import time
import sys

def main():
    print("Hello from smart-gmcp!", flush=True)
    try:
        while True:
            # do your real work here
            time.sleep(5)
    except KeyboardInterrupt:
        print("Shutting down...", flush=True)
        sys.exit(0)

if __name__ == "__main__":
    main()
