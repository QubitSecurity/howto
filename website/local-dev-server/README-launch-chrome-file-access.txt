How to use (Windows):
1) Download 'launch_chrome_file_access.bat' to any folder.
2) Double-click it. It will open the default page:
     C:\Users\eliot\Desktop\plura-index-6.0\ko\customer.html
   - OR - Drag & drop any HTML file onto the .bat to open that file.
3) This launches Chrome with the flag:
     --allow-file-access-from-files
   and a temporary profile so your main Chrome profile is untouched.
4) Close the Chrome window when done. You can delete the temp profile at:
     %TEMP%\chrome-file-access-profile
Notes:
- Use ONLY for local development. Do not browse the internet with this window.
- If Chrome is not found, edit the .bat and set the CHROME path manually.
