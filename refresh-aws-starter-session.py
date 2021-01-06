# -*- coding: utf-8 -*
import warnings
import os
import argparse
import time
from selenium import webdriver
from selenium.webdriver import FirefoxOptions
from selenium.webdriver import Firefox
warnings.filterwarnings("ignore")


def get_aws_credentials(email, pw):
    opts = FirefoxOptions()
    opts.add_argument("--headless")
    driver = Firefox(firefox_options=opts)
    # driver = webdriver.Remote(
    #     command_executor='http://localhost:4444/wd/hub',
    #     options=opts
    # )
    driver.get('https://www.awseducate.com/signin/SiteLogin')
    driver.find_element_by_name("loginPage:siteLogin:loginComponent:loginForm:username").send_keys(email)
    driver.find_element_by_name("loginPage:siteLogin:loginComponent:loginForm:password").send_keys(pw)
    sign_in_button = driver.find_element_by_class_name("loginText")
    time.sleep(3)
    sign_in_button.click()
    time.sleep(20)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())+"\t"+"Login...")
    aws_account = driver.find_elements_by_xpath("//a[@class='hdNavTop']")[4]
    aws_account.click()
    time.sleep(20)
    credit = driver.find_element_by_class_name("uiOutputRichText").find_elements_by_tag_name("strong")[0].text
    endtime = driver.find_element_by_class_name("uiOutputRichText").find_elements_by_tag_name("strong")[1].text
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())+"\t"+"Credits: 【"+credit+"】,End Time: 【"+ endtime+"】")
    account = driver.find_element_by_class_name("btn")
    account.click()
    currentTab = driver.current_window_handle
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())+"\t"+"Go Vocareum...")
    time.sleep(20)
    vocareum_tab = driver.window_handles[1]
    driver.switch_to.window(vocareum_tab)
    account_details = driver.find_element_by_id("showawsdetail")
    account_details.click()
    time.sleep(10)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())+"\t"+"Get Credentail...")
    show_key_btn = driver.find_element_by_id("clikeyboxbtn")
    show_key_btn.click()
    time.sleep(5)
    span_tags = driver.find_elements_by_tag_name("span")
    for tag in span_tags:
        if '[default]' in tag.text:
            text = tag.text
            return driver,text

def arg_parser():
    parser = argparse.ArgumentParser(description='For Credentials of AWS Starter')
    parser.add_argument('--email', '-e', metavar="your@mail.com", required=True)
    parser.add_argument('--pw', '-p', metavar='passwd', required=True)
    parser.add_argument('--config', '-f', metavar='aws config file path',default='/root/.aws/credentials')
    args = parser.parse_args()
    return args
    
def main():
    args = arg_parser()
    try:
        driver.quit()
    except:
        pass
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())+"\t"+"Starting...")
    driver, content = get_aws_credentials(args.email, args.pw)
    credentials = [v.strip() + '\n' for v in content.split()]
    print("**************************************************************************")
    print(credentials)
    print("**************************************************************************")
    file = open(args.config, "w")
    file.writelines(credentials)
    file.close()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())+"\t"+"Writing Config...")
    driver.delete_all_cookies()
    driver.close()
    driver.quit()

if __name__ == "__main__":
    main()
