#!/bin/bash
# Rocky8 KVM에서 생성한 가상머신을 Rocky9 KVM 환경에서 사용하기 위한 가상머신 xml 변환 쉘 스크립트
# 사용법: ./convert_xml.sh <xml 파일이 있는 디렉토리>
TARGET_DIR="$1"

if [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory not found -> $TARGET_DIR"
    exit 1
fi

# 처리 시작
echo "[INFO] XML 변환 시작 - 대상 디렉토리: $TARGET_DIR"

for xml in "$TARGET_DIR"/*.xml; do
    [ -e "$xml" ] || continue

    echo "[INFO] 변환 중: $xml"

    # 백업 생성
    cp "$xml" "$xml.bak"

    # 1. qxl → virtio video 모델 변환
    sed -i \
        "s|<model type='qxl'[^>]*/>|<model type='virtio' heads='1' primary='yes'/>|" \
        "$xml"

    # 2. graphics spice → vnc 로 대체
    sed -i \
        "s|<graphics type='spice' autoport='yes'>|<graphics type='vnc' port='-1' autoport='yes'>|" \
        "$xml"

    # 3. <image compression='off'/> 제거
    sed -i \
        "/<image compression='off'\/>/d" \
        "$xml"

    # 4. spice channel 전체 블록 삭제
    sed -i \
        "/<channel type='spicevmc'>/,/<\/channel>/d" \
        "$xml"

    # 5. <audio id='1' type='spice'/> 삭제
    sed -i \
        "/<audio id='1' type='spice'\/>/d" \
        "$xml"

    # 6. <redirdev ... type='spicevmc'> 블록 전체 삭제 (2개 이상 가능)
    sed -i \
        "/<redirdev bus='usb' type='spicevmc'>/,/<\/redirdev>/d" \
        "$xml"

    echo "[OK] 완료: $xml"
done

echo "[DONE] 모든 XML 파일 변환 완료."
