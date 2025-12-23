import subprocess
import os
import json

def show_menu():
    menu = "YOUTUBE\n1. Search\n2. Exit"
    process = subprocess.Popen(['fzf'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout_data, _ = process.communicate(input=menu.encode('utf-8'))
    return stdout_data.decode('utf-8').strip()

def search_videos(query):
    search_cmd = ['yt-dlp', '--flat-playlist', '-J', f'ytsearch40:{query}']
    result = subprocess.run(search_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("Error during video search:", result.stderr)
        return []
    data = json.loads(result.stdout)
    return [(entry['title'], entry['id']) for entry in data['entries']]

def select_media_type():
    options = [
        "1. Video + Audio",
        "2. Video Only",
        "3. Audio Only",
        "4. Back"
    ]
    process = subprocess.Popen(['fzf'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, _ = process.communicate(input="\n".join(options).encode('utf-8'))
    choice = stdout.decode('utf-8').strip()
    return choice

def select_video_quality(media_type):
    if media_type == "3. Audio Only":
        options = [
            "1. 128k",
            "2. 160k",
            "3. 192k",
            "4. 256k",
            "5. 320k",
            "6. Best Available",
            "7. Back"
        ]
    else:
        options = [
            "1. 144p", "2. 240p", "3. 360p", "4. 480p",
            "5. 720p", "6. 1080p", "7. 1440p", "8. 2160p",
            "9. Best Available", "10. Back"
        ]
    
    process = subprocess.Popen(['fzf'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, _ = process.communicate(input="\n".join(options).encode('utf-8'))
    return stdout.decode('utf-8').strip()

def select_video(video_list):
    video_list.append(("Back", "back"))
    titles = "\n".join([f"{i+1}. {video[0]}" for i, video in enumerate(video_list)])
    process = subprocess.Popen(['fzf'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, _ = process.communicate(input=titles.encode('utf-8', errors='ignore'))
    selected_line = stdout.decode('utf-8', errors='ignore').strip()

    if not selected_line:
        return None

    index_str = selected_line.split(".")[0]
    if index_str.isdigit():
        index = int(index_str) - 1
        if 0 <= index < len(video_list):
            selected = video_list[index]
            return "back" if selected[1] == "back" else selected
    return None

def get_quality_format(quality_choice, media_type):
    if media_type == "3. Audio Only":
        quality_map = {
            "1. 128k": "128",
            "2. 160k": "160",
            "3. 192k": "192",
            "4. 256k": "256",
            "5. 320k": "320",
            "6. Best Available": "best"
        }
        return quality_map.get(quality_choice, "best")
    else:
        quality_map = {
            "1. 144p": "144", "2. 240p": "240", "3. 360p": "360",
            "4. 480p": "480", "5. 720p": "720", "6. 1080p": "1080",
            "7. 1440p": "1440", "8. 2160p": "2160", "9. Best Available": "best"
        }
        return quality_map.get(quality_choice, "best")

def download_media(video_url, media_type, quality):
    media_type_map = {
        "1. Video + Audio": f'bestvideo[height<={quality}]+bestaudio/best' if quality != "best" else 'bestvideo+bestaudio/best',
        "2. Video Only": f'bestvideo[height<={quality}]' if quality != "best" else 'bestvideo',
        "3. Audio Only": f'bestaudio[abr<={quality}]' if quality != "best" else 'bestaudio'
    }
    
    format_str = media_type_map.get(media_type, 'best')
    output_template = '%(title)s.%(ext)s'
    os.system(f'yt-dlp -f "{format_str}" -o "{output_template}" "{video_url}"')

def play_media(video_url, media_type, quality):
    media_type_map = {
        "1. Video + Audio": f'bestvideo[height<={quality}]+bestaudio/best' if quality != "best" else 'bestvideo+bestaudio/best',
        "2. Video Only": f'bestvideo[height<={quality}]' if quality != "best" else 'bestvideo',
        "3. Audio Only": f'bestaudio[abr<={quality}]' if quality != "best" else 'bestaudio'
    }
    
    format_str = media_type_map.get(media_type, 'best')
    print(f"Playing media with format: {format_str}")
    os.system(f'mpv --no-video --ytdl-format="{format_str}" "{video_url}"' if media_type == "3. Audio Only" 
              else f'mpv --ytdl-format="{format_str}" "{video_url}"')

def main():
    while True:
        main_choice = show_menu()
        if main_choice == "2. Exit":
            print("Exiting program.")
            break
        if main_choice != "1. Search":
            print("Invalid selection, please try again.")
            continue

        query = input("Enter your search query: ")
        video_list = search_videos(query)
        if not video_list:
            print("No videos found for your search.")
            continue

        while True:
            video_choice = select_video(video_list)
            if not video_choice:
                break
            if video_choice == "back":
                break

            video_url = f"https://www.youtube.com/watch?v={video_choice[1]}"
            
            while True:
                media_type = select_media_type()
                if media_type == "4. Back":
                    break
                if not media_type:
                    continue

                while True:
                    quality_choice = select_video_quality(media_type)
                    if quality_choice.endswith("Back"):
                        break
                    if not quality_choice:
                        continue

                    quality = get_quality_format(quality_choice, media_type)
                    if quality == "back":
                        continue

                    action = select_play_or_download()
                    if action == "3. Back":
                        break
                    if action == "1. Play":
                        play_media(video_url, media_type, quality)
                    elif action == "2. Download":
                        download_media(video_url, media_type, quality)

def select_play_or_download():
    options = ["1. Play", "2. Download", "3. Back"]
    process = subprocess.Popen(['fzf'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, _ = process.communicate(input="\n".join(options).encode('utf-8'))
    choice = stdout.decode('utf-8').strip()
    return choice

if __name__ == "__main__":
    main()

