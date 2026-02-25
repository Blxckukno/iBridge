
import cv2
import numpy as np
import os

# Folder containing collage images
COLLAGE_DIR = r"C:\Users\Lwandile Gasela\Downloads\Images-Collage"
OUTPUT_DIR = r"C:\Users\Lwandile Gasela\iBridge\Archives\decollaged_images"
MARGIN = 20  # pixels of margin to add around each cropped image

os.makedirs(OUTPUT_DIR, exist_ok=True)

def remove_white_border(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
    coords = cv2.findNonZero(thresh)
    if coords is not None:
        x, y, w, h = cv2.boundingRect(coords)
        return img[y:y+h, x:x+w]
    else:
        return img

def decollage_image(image_path, output_dir, margin=20, prefix=None):
    image = cv2.imread(image_path)
    if image is None:
        print(f"Could not read {image_path}")
        return 0
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    bounding_boxes = [cv2.boundingRect(c) for c in contours]
    boxes = sorted(bounding_boxes, key=lambda b: (b[1], b[0]))
    count = 0
    for idx, (x, y, w, h) in enumerate(boxes):
        x1 = max(x - margin, 0)
        y1 = max(y - margin, 0)
        x2 = min(x + w + margin, image.shape[1])
        y2 = min(y + h + margin, image.shape[0])
        crop = image[y1:y2, x1:x2]
        crop = remove_white_border(crop)
        base = os.path.splitext(os.path.basename(image_path))[0]
        out_name = f"{prefix or base}_person_{idx+1}.png"
        out_path = os.path.join(output_dir, out_name)
        cv2.imwrite(out_path, crop)
        print(f"Saved: {out_path}")
        count += 1
    return count

total = 0
for fname in os.listdir(COLLAGE_DIR):
    if fname.lower().endswith(('.png', '.jpg', '.jpeg')):
        img_path = os.path.join(COLLAGE_DIR, fname)
        print(f"Processing {img_path}...")
        n = decollage_image(img_path, OUTPUT_DIR, MARGIN)
        total += n
print(f"Done! {total} images saved to {OUTPUT_DIR}")
