"""Import the approved v11 art and build editable native resources and asset scenes."""
from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art-review/animation-review-v11'
manifest=json.loads((SOURCE/'manifest.json').read_text())
assets={a['name']:a for a in manifest['assets']}
records=[]
def write(path,text):
 p=ROOT/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
def texture(name):return 'res://assets/arcade/'+assets[name]['file']
def resource(name):return 'res://resources/arcade/'+name+'.tres'
def frames(name):
 a=assets[name];chunks=['[gd_resource type="SpriteFrames" format=3]','',f'[ext_resource type="Texture2D" path="{texture(name)}" id="1"]','']
 for i in range(a['frames']):
  chunks.extend([f'[sub_resource type="AtlasTexture" id="Frame_{i}"]','atlas = ExtResource("1")',f'region = Rect2({i%a["columns"]*a["width"]}, {i//a["columns"]*a["height"]}, {a["width"]}, {a["height"]})','filter_clip = true',''])
 anims=[]
 for tag,first,last in a['tags'] or [['default',1,a['frames']]]:
  loop=tag not in ['death','break','disappear','center','arm','tip']
  fs=', '.join('{"duration": 1.0, "texture": SubResource("Frame_%d")}'%i for i in range(first-1,last))
  anims.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %.9f}'%(fs,str(loop).lower(),tag,1/a['seconds']))
 chunks.extend(['[resource]','animations = ['+',\n'.join(anims)+']',''])
 write('resources/arcade/'+name+'.tres','\n'.join(chunks))
def scene(path,name,root_type,asset,script=None,animation=None,collider=None,layer=0,mask=0,props='',offset=0,frame=0):
 exts=[f'[ext_resource type="Texture2D" path="{texture(asset)}" id="2"]'] if not animation else [f'[ext_resource type="SpriteFrames" path="{resource(asset)}" id="2"]']
 if script:exts.insert(0,f'[ext_resource type="Script" path="res://{script}" id="1"]')
 c=['[gd_scene format=3]','']+exts+['']
 if collider:c+=['[sub_resource type="RectangleShape2D" id="Shape"]',f'size = Vector2({collider[0]}, {collider[1]})','']
 c+=[f'[node name="{name}" type="{root_type}"]','texture_filter = 1']
 if script:c+=['script = ExtResource("1")']
 if root_type in ['StaticBody2D','CharacterBody2D','Area2D']:c += [f'collision_layer = {layer}',f'collision_mask = {mask}']
 if props:c+=[props]
 if animation:c+=['','[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]','sprite_frames = ExtResource("2")',f'animation = &"{animation}"',f'autoplay = "{animation}"',f'position = Vector2(0, {offset})']
 else:
  a=assets[asset];c+=['','[node name="Sprite2D" type="Sprite2D" parent="."]','texture = ExtResource("2")',f'hframes = {a["columns"]}',f'vframes = {(a["frames"]+a["columns"]-1)//a["columns"]}',f'frame = {frame}']
 if collider:c+=['','[node name="CollisionShape2D" type="CollisionShape2D" parent="."]','shape = SubResource("Shape")',f'position = Vector2(0, {collider[2] if len(collider)>2 else 0})']
 write(path,'\n'.join(c)+'\n');records.append({'asset':asset,'scene':'res://'+path,'collision':{'type':root_type,'size':collider[:2],'layer':layer,'mask':mask} if collider else {'type':'none','reason':'Decorative visual; no world blocking or detection required'}})
def inherit(path,name,base,props):write(path,f'[gd_scene format=3]\n\n[ext_resource type="PackedScene" path="res://{base}" id="1"]\n\n[node name="{name}" instance=ExtResource("1")]\n{props}\n')
for name,a in assets.items():
 source=SOURCE/a['file'];assert hashlib.sha256(source.read_bytes()).hexdigest()==a['sha256_png']
 dest=ROOT/'assets/arcade'/a['file'];dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
 if a['tags']:frames(name)
for color in ['white','coral','lime','violet']:
 name='bomber_'+color
 scene('scenes/arcade/characters/'+name+'.tscn','Bomber'+color.title(),'CharacterBody2D',name,'scripts/entities/player.gd','idle_front',[60,48,6],4,19,f'skin = "{color}"',-30)
inherit('scenes/entities/player.tscn','Player','scenes/arcade/characters/bomber_white.tscn','')
inherit('scenes/entities/ai_bomber.tscn','AiBomber','scenes/arcade/characters/bomber_coral.tscn','')
p=ROOT/'scenes/entities/ai_bomber.tscn';s=p.read_text().replace('[node name=', '[ext_resource type="Script" path="res://scripts/entities/ai_bomber.gd" id="2"]\n\n[node name=');p.write_text(s+'script = ExtResource("2")\n')
for enemy in ['ballom','onil','dahl','minvo','doria','ovape','pass','pontan']:
 scene('scenes/arcade/enemies/'+enemy+'.tscn',enemy.title(),'CharacterBody2D','enemy_'+enemy,'scripts/entities/enemy.gd','move_down',[56,44,8],8,17 if enemy in ['doria','ovape','pontan'] else 19,f'type_name = "{enemy}"',-30)
inherit('scenes/entities/enemy.tscn','Enemy','scenes/arcade/enemies/ballom.tscn','')
terrain=['floor','stone','brick','exit_closed','exit_open','floor_2','floor_3','vine_stone']
for i,name in enumerate(terrain):
 block=name in ['stone','brick','vine_stone','exit_closed'];portal=name=='exit_open'
 scene('scenes/arcade/terrain/'+name+'.tscn',name.title().replace('_',''),'StaticBody2D' if block else 'Area2D' if portal else 'Node2D','exit-open' if name=='exit_open' else 'terrain',animation='glow' if name=='exit_open' else None,collider=[64,64] if block else [48,48] if portal else None,layer=2 if name=='brick' else 1 if block else 128 if portal else 0,mask=4 if portal else 0,frame=i)
scene('scenes/entities/bomb.tscn','Bomb','StaticBody2D','bomb','scripts/entities/bomb.gd','fuse',[56,56],16,0)
for i,kind in enumerate(['center','arm','tip']):
 scene('scenes/arcade/effects/flame_'+kind+'.tscn','Flame'+kind.title(),'Area2D','explosion','scripts/entities/flame.gd',kind,[64,64],64,12,'kind = '+str(i))
inherit('scenes/entities/flame.tscn','Flame','scenes/arcade/effects/flame_center.tscn','')
for name,asset,anim in [('brick_break','brick-break','break'),('puff','puff','disappear')]:
 scene('scenes/effects/'+name+'.tscn',name.title().replace('_',''),'Node2D',asset,'scripts/effects/frame_burst.gd',anim,props='animation_name = &"'+anim+'"')
for i,name in enumerate(['fire','bomb','speed','wall_pass','bomb_pass','remote','shield','mystery']):
 scene('scenes/arcade/pickups/'+name+'.tscn',name.title().replace('_',''),'Area2D','powerups','scripts/entities/power_up.gd',collider=[48,48],layer=32,mask=4,props='kind = '+str(i),frame=i)
inherit('scenes/entities/power_up.tscn','PowerUp','scenes/arcade/pickups/fire.tscn','')
for name,a in assets.items():
 if a['family']!='ui':continue
 # Atlas components and screens remain reusable native Controls at their original dimensions.
 ext=f'[ext_resource type="Texture2D" path="{texture(name)}" id="1"]'
 for i in range(a['frames']):
  suffix='' if a['frames']==1 else '_'+str(i)
  path='scenes/arcade/ui/'+name+suffix+'.tscn'
  sub='' if a['frames']==1 else f'\n[sub_resource type="AtlasTexture" id="Atlas"]\natlas = ExtResource("1")\nregion = Rect2({i%a["columns"]*a["width"]}, {i//a["columns"]*a["height"]}, {a["width"]}, {a["height"]})\nfilter_clip = true\n'
  tex='ExtResource("1")' if a['frames']==1 else 'SubResource("Atlas")'
  write(path,f'[gd_scene format=3]\n\n{ext}\n{sub}\n[node name="Artwork" type="TextureRect"]\ntexture_filter = 1\noffset_right = {a["width"]}.0\noffset_bottom = {a["height"]}.0\ntexture = {tex}\nmouse_filter = 2\n')
  records.append({'asset':name,'scene':'res://'+path,'collision':{'type':'Control','reason':'UI uses Control hit rectangles; does not block the game world'}})
write('assets/arcade/manifest.json',json.dumps({'source':'animation-review-v11','source_manifest_sha256':hashlib.sha256((SOURCE/'manifest.json').read_bytes()).hexdigest(),'approval':'User approved import, scenes, collisions and removal of old art in this task','assets':manifest['assets'],'scenes':records},indent=2)+'\n')
print('Imported',len(assets),'approved sheets; created',len(records),'asset scenes with collision policies.')
