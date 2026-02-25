import os
from PIL import Image
import cv2
import torch
from realesrgan import RealESRGAN

def is_blurry(image_path, threshold=100.0):
    img = cv2.imread(image_path)
    if img is None:
        return True
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    return laplacian_var < threshold

def enhance_image(input_path, output_path, device):
    img = Image.open(input_path).convert('RGB')
    model = RealESRGAN(device, scale=4)
    model.load_weights('RealESRGAN_x4.pth', download=True)
    sr_image = model.predict(img)
    sr_image.save(output_path)

def main():
    folder = r'C:/Users/Lwandile Gasela/iBridge/Website/images/generated-hq'
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    for filename in os.listdir(folder):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
            file_path = os.path.join(folder, filename)
            print(f'Processing {filename}...')
            if is_blurry(file_path):
                print(f'  {filename} is blurry. Attempting to regenerate...')
                try:
                    enhance_image(file_path, file_path, device)
                    print(f'  Enhanced {filename}.')
                except Exception as e:
                    print(f'  Failed to enhance {filename}: {e}')
            else:
                try:
                    enhance_image(file_path, file_path, device)
                    print(f'  Enhanced {filename}.')
                except Exception as e:
                    print(f'  Failed to enhance {filename}: {e}')

if __name__ == '__main__':
    main()
