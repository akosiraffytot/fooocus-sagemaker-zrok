import subprocess
from multiprocessing import Process
import time

def run_command1():
    subprocess.run(["zrok", "share", "public", "http://localhost:7865", "--headless"])

def run_command2():
    time.sleep(2)
    subprocess.run(["python", "Fooocus/entry_with_update.py", "--always-high-vram", "--theme", "dark"])

if __name__ == "__main__":
    p1 = Process(target=run_command1)
    p2 = Process(target=run_command2)
    p1.start()
    p2.start()
    p1.join()
    p2.join()

print("Fooocus and Zrok started successfully!")