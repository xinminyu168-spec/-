from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools import subset
root=Path(__file__).resolve().parent.parent
font=TTFont('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',fontNumber=2)
text=''.join(p.read_text() for folder in ['scripts','scenes'] for p in (root/folder).rglob('*') if p.suffix in ['.gd','.tscn'])
options=subset.Options(); options.layout_features=['*']
job=subset.Subsetter(options=options); job.populate(unicodes=set(map(ord,text))|set(range(32,127)));job.subset(font)
for number,value in [(1,'NTM Prototype Subset'),(2,'Regular'),(4,'NTM Prototype Subset Regular'),(6,'NTMPrototypeSubset-Regular')]:
    for platform,encoding,language in [(3,1,0x409),(1,0,0)]: font['name'].setName(value,number,platform,encoding,language)
cff=font['CFF '].cff; cff.fontNames=['NTMPrototypeSubset-Regular']; cff.topDictIndex[0].FamilyName='NTM Prototype Subset'; cff.topDictIndex[0].FullName='NTM Prototype Subset Regular'
font.save(root/'assets/fonts/ntm-ui.otf')
print('Chinese font updated:',len(font.getBestCmap()),'characters')
