function ocr --description "Copy text from a screen region"
    set -l text (dms screenshot region --stdout --no-file --no-clipboard --no-notify | tesseract stdin stdout -l eng+rus+ukr 2>/dev/null | string collect)
    if test -z (string trim -- "$text")
        notify-send -e -t 1500 -a OCR "No text found"
        return 1
    end
    printf '%s' "$text" | wl-copy
    notify-send -e -t 1500 -a OCR "Text copied"
end
