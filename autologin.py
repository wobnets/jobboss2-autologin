from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
import os
import signal

# Ensure the DISPLAY environment variable is set
os.environ["DISPLAY"] = ":0"

USERNAME = os.environ.get("JOBBOSS_USER")
PASSWORD = os.environ.get("JOBBOSS_PASSWORD")

options = webdriver.ChromeOptions()
options.add_argument("--kiosk")
options.add_argument("--no-first-run")
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")
options.add_argument("disable-infobars")
options.add_experimental_option("detach", True)  # Keep the browser open

options.add_experimental_option(
    "prefs",
    {"credentials_enable_service": False, "profile.password_manager_enabled": False},
)

options.add_experimental_option("excludeSwitches", ["enable-automation"])
options.add_experimental_option("useAutomationExtension", False)

options.add_argument("--enable-logging")
options.add_argument("--v=1")

driver = webdriver.Chrome(options=options)

wait = WebDriverWait(driver, 10)

url = "http://192.168.1.64/jobboss2"
driver.get(url)

username_input = driver.find_element(By.ID, "username")
password_input = driver.find_element(By.ID, "password")
login_button = driver.find_element(By.ID, "login")

username_input.click()
username_input.send_keys(USERNAME)
password_input.click()
password_input.send_keys(PASSWORD)
login_button.click()

data_collection_button = wait.until(
    EC.element_to_be_clickable(
        (By.CSS_SELECTOR, "#product-datacollection .widget-main")
    )
)

data_collection_button.click()

try:
    active_session_yes = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable(
            (
                By.CSS_SELECTOR,
                "#baseModal > div > div > div.modal-footer > span > button:nth-child(2)",
            )
        )
    )
    active_session_yes.click()
except Exception as e:
    print("The button did not become clickable within 10 seconds.")

# wait until the navbar is visible, then hide it, if it is not found within 10 seconds, continue
try:
    navbar = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, "navbar"))
    )
    driver.execute_script("arguments[0].style.display = 'none';", navbar)
except Exception as e:
    print("The navbar did not become clickable within 10 seconds.")

try:
    header = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, "st-header"))
    )
    driver.execute_script("arguments[0].style.display = 'none';", header)
except Exception as e:
    print("The header did not become clickable within 10 seconds.")


# keep the script running
def signal_handler(sig, frame):
    print("Signal received, closing browser...")
    driver.quit()
    exit(0)


signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

# Keep the script running
signal.pause()
