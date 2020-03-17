// Supports dragging and dropping files or links
// Bookmarklet Converter: https://www.yourjs.com/bookmarklet/
// Texture URL at index: gShaderToy.mEffect.mPasses[gShaderToy.mActiveDoc].mInputs[index]
function setTexture(index, url) {
  gShaderToy.SetTexture(index,
    {
      mSrc: url,
      mType: 'texture',
      mID: 1,
      mSampler: {
        filter: 'mipmap', wrap: 'repeat', vflip: 'true', srgb: 'false', internal: 'byte',
      },
    });
}

setTexture(0, 'https://raw.githubusercontent.com/AlphaModder/raymarched-sundial/master/textures/Sand_006_baseColor.jpg');
setTexture(1, 'https://www.shadertoy.com/media/a/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg');
setTexture(2, 'https://raw.githubusercontent.com/AlphaModder/raymarched-sundial/master/textures/Sand_006_normal.jpg');
setTexture(3, 'https://raw.githubusercontent.com/AlphaModder/raymarched-sundial/master/textures/pyramid.jpg');

for (let i = 0; i < 4; i += 1) {
  const iChannel = document.getElementById(`myUnitCanvas${i}`);
  iChannel.addEventListener('drop', (e) => {
    e.stopPropagation();
    e.preventDefault();
    const url = e.dataTransfer.getData('text');
    if (url) {
      setTexture(i, url);
    } else {
      const file = e.dataTransfer.files[0];
      const freader = new FileReader();
      freader.onload = () => {
        setTexture(i, freader.result);
      };
      freader.readAsDataURL(file);
    }
  });
  iChannel.addEventListener('dragover', (e) => {
    e.stopPropagation();
    e.preventDefault();
  });
}
