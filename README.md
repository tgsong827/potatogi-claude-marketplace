## Install Marketplace using settings.json
사요하려는 claude code 환경에서 settings.json을 수정하여 Marketplace를 설치할 수 있습니다.
```
"extraKnownMarketplaces": {
  "potatogi-plugin-marketplace": {
    "source": {
      "source": "git",
      "url": "git@github.com:tgsong827/potatogi-claude-marketplace.git"
    }
  }
},
```
