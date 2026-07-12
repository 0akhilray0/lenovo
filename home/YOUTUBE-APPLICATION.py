import subprocess
import os
import json
import re

def run_fzf(options):
    """Helper function to run fzf with a list of options."""
    try:
        process = subprocess.Popen(
            ['fzf'], 
            stdin=subprocess.PIPE, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE
        )
        input_data = "\n".join(options).encode('utf-8')
        stdout_data, stderr_data = process.communicate(input=input_data)
        
        if process.returncode != 0:
            # fzf returns 1 if no match was found, 2 if an error occurred, 130 if aborted by user (ESC/Ctrl-C)
            if process.returncode == 130:
                 return None # User cancelled
            return None

        return stdout_data.decode('utf-8').strip()
    except FileNotFoundError:
         print("Error: 'fzf' is not installed or not in your PATH. Please install it.")
         return None

def show_menu():
    options = ["1. Search", "2. Exit"]
    print("\n--- YOUTUBE CLI ---")
    return run_fzf(options)

def search_videos(query):
    print(f"Searching for: {query}...")
    search_cmd = ['yt-dlp', '--flat-playlist', '-J', f'ytsearch40:{query}']
    
    try:
        result = subprocess.run(search_cmd, capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)
        
        if 'entries' not in data or not data['entries']:
             return []
             
        return [(entry.get('title', 'Unknown Title'), entry.get('id', 'Unknown ID')) for entry in data['entries'] if entry.get('id')]
        
    except subprocess.CalledProcessError as e:
        print(f"Error executing yt-dlp search: {e.stderr}")
        return []
    except json.JSONDecodeError:
        print("Error: Failed to parse search results from yt-dlp.")
        return []
    except FileNotFoundError:
        print("Error: 'yt-dlp' is not installed or not in your PATH. Please install it.")
        return []

def select_media_type():
    options = [
        "1. Video + Audio",
        "2. Video Only",
        "3. Audio Only",
        "4. Back"
    ]
    return run_fzf(options)

def select_video_quality(media_type):
    if "Audio Only" in media_type:
        options = [
            "1. 128k", "2. 160k", "3. 192k", "4. 256k", "5. 320k", "6. Best Available", "7. Back"
        ]
    else:
        options = [
            "1. 144p", "2. 240p", "3. 360p", "4. 480p", "5. 720p", "6. 1080p", "7. 1440p", "8. 2160p", "9. Best Available", "10. Back"
        ]
    return run_fzf(options)

def select_video(video_list):
    options = [f"{i+1}. {video[0]}" for i, video in enumerate(video_list)]
    options.append("0. Back")
    
    selected_line = run_fzf(options)
    
    if not selected_line:
        return None

    if selected_line == "0. Back":
        return "back"

    try:
        index = int(selected_line.split(".")[0]) - 1
        if 0 <= index < len(video_list):
            return video_list[index]
    except ValueError:
        return None
        
    return None

def get_quality_format(quality_choice, media_type):
    if not quality_choice:
        return "best"
        
    if "Audio Only" in media_type:
        quality_map = {
            "1": "128", "2": "160", "3": "192", "4": "256", "5": "320", "6": "best"
        }
    else:
        quality_map = {
            "1": "144", "2": "240", "3": "360", "4": "480", "5": "720", "6": "1080", "7": "1440", "8": "2160", "9": "best"
        }
        
    key = quality_choice.split(".")[0]
    return quality_map.get(key, "best")

def select_time_span():
    """Allows user to select a time span or download full video."""
    options = [
        "1. Download Full Video",
        "2. Custom Time Span (e.g., 1 min to 10 min)",
        "3. Back"
    ]
    
    choice = run_fzf(options)
    
    if not choice or choice.startswith("3") or choice == "0. Back":
        return "back"
        
    if choice.startswith("1"):
        return "full"
        
    if choice.startswith("2"):
        while True:
            start_time = input("Enter start time (Format HH:MM:SS or MM:SS, e.g., 01:30 or 00:01:30): ").strip()
            end_time = input("Enter end time (Format HH:MM:SS or MM:SS, e.g., 10:00 or 00:10:00): ").strip()
            
            # Basic validation for time format (HH:MM:SS or MM:SS)
            time_pattern = re.compile(r'^(\d{1,2}:)?\d{1,2}:\d{2}$')
            
            if not time_pattern.match(start_time) or not time_pattern.match(end_time):
                print("Invalid time format. Please use HH:MM:SS or MM:SS. Try again.")
                continue
                
            return f"*{start_time}-{end_time}"
            
    return "back"

def get_format_string(media_type, quality):
    if "Audio Only" in media_type:
        return f'bestaudio[abr<={quality}]' if quality != "best" else 'bestaudio'
    elif "Video Only" in media_type:
        return f'bestvideo[height<={quality}]' if quality != "best" else 'bestvideo'
    else: # Video + Audio
        return f'bestvideo[height<={quality}]+bestaudio/best' if quality != "best" else 'bestvideo+bestaudio/best'

def download_media(video_url, media_type, quality, time_span):
    format_str = get_format_string(media_type, quality)
    output_template = '%(title)s.%(ext)s'
    
    cmd = ['yt-dlp', '-f', format_str, '-o', output_template]
    
    if time_span != "full":
        # Uses stream copying instead of re-encoding for massive speed improvements
        cmd.extend(['--download-sections', time_span])
        print(f"Downloading section: {time_span.replace('*', '')}")
    else:
        print("Downloading full video...")
        
    cmd.append(video_url)
    
    try:
        subprocess.run(cmd, check=True)
        print("Download complete!")
    except subprocess.CalledProcessError as e:
         print(f"Download failed. Please ensure 'ffmpeg' is installed if you are downloading time spans. Error: {e}")
    except FileNotFoundError:
         print("Error: 'yt-dlp' is not installed or not in your PATH.")

def play_media(video_url, media_type, quality):
    format_str = get_format_string(media_type, quality)
    print(f"Playing media with format: {format_str}")
    
    cmd = ['mpv', f'--ytdl-format={format_str}']
    
    if "Audio Only" in media_type:
        cmd.append('--no-video')
        
    cmd.append(video_url)
    
    try:
        subprocess.run(cmd)
    except FileNotFoundError:
        print("Error: 'mpv' is not installed or not in your PATH. Please install it.")

def select_play_or_download():
    options = ["1. Play", "2. Download", "3. Back"]
    return run_fzf(options)

def main():
    while True:
        main_choice = show_menu()
        
        if not main_choice or main_choice.startswith("2"):
            print("Exiting program.")
            break
            
        if not main_choice.startswith("1"):
            continue

        query = input("Enter your search query: ")
        if not query.strip():
             continue
             
        video_list = search_videos(query)
        if not video_list:
            print("No videos found or an error occurred.")
            continue

        while True: # Video Selection Loop
            video_choice = select_video(video_list)
            
            if not video_choice or video_choice == "back":
                break

            video_url = f"https://www.youtube.com/watch?v={video_choice[1]}"
            print(f"Selected: {video_choice[0]}")
            
            while True: # Media Type Loop
                media_type = select_media_type()
                
                if not media_type or media_type.startswith("4"):
                    break

                while True: # Quality Loop
                    quality_choice = select_video_quality(media_type)
                    
                    if not quality_choice or "Back" in quality_choice:
                        break

                    quality = get_quality_format(quality_choice, media_type)

                    while True: # Action Loop (Play/Download)
                        action = select_play_or_download()
                        
                        if not action or action.startswith("3"):
                            break
                            
                        if action.startswith("1"): # Play
                            play_media(video_url, media_type, quality)
                            
                        elif action.startswith("2"): # Download
                            time_span = select_time_span()
                            if time_span == "back":
                                continue # Go back to Play/Download menu
                            
                            download_media(video_url, media_type, quality, time_span)

if __name__ == "__main__":
    main()
