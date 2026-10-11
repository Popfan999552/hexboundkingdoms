#!/usr/bin/env python3
"""Official bundletool validation and final permission/SDK audit for actual AABs."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,urllib.request,xml.etree.ElementTree as ET
VERSION='1.18.3'
DIGEST='a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29'
ANDROID='{http://schemas.android.com/apk/res/android}'
def main(bundle):
 cache=Path(os.environ.get('XDG_CACHE_HOME','/tmp/hexbound-cache')); cache.mkdir(parents=True,exist_ok=True)
 jar=cache/f'bundletool-all-{VERSION}.jar'
 if not jar.exists(): urllib.request.urlretrieve(f'https://github.com/google/bundletool/releases/download/{VERSION}/{jar.name}',jar)
 if hashlib.file_digest(jar.open('rb'),'sha256').hexdigest()!=DIGEST: raise SystemExit('bundletool checksum mismatch')
 java=str(Path(os.environ['JAVA_HOME'])/'bin/java')
 subprocess.run([java,'-jar',str(jar),'validate','--bundle='+bundle],check=True)
 manifest=subprocess.check_output([java,'-jar',str(jar),'dump','manifest','--bundle='+bundle],text=True)
 Path('build/AndroidManifest.xml').write_text(manifest)
 root=ET.fromstring(manifest)
 if root.attrib.get('package')!='com.hexboundkingdoms.game': raise SystemExit('Unexpected package ID')
 sdk=root.find('uses-sdk')
 if sdk is None or sdk.get(ANDROID+'targetSdkVersion')!='36' or sdk.get(ANDROID+'minSdkVersion')!='26': raise SystemExit('Unexpected minimum/target SDK')
 application=root.find('application')
 if application is None or application.get(ANDROID+'allowBackup')!='false': raise SystemExit('App backup must be disabled')
 if application.get(ANDROID+'debuggable','false')!='false': raise SystemExit('Release app must not be debuggable')
 permissions=sorted(p.get(ANDROID+'name') for p in root.findall('uses-permission'))
 ads=os.environ.get('HEXBOUND_TEST_ADS')=='1'
 allowed={'android.permission.INTERNET','android.permission.ACCESS_NETWORK_STATE','android.permission.AD_ID','com.google.android.gms.permission.AD_ID','android.permission.ACCESS_ADSERVICES_AD_ID','android.permission.ACCESS_ADSERVICES_ATTRIBUTION','android.permission.ACCESS_ADSERVICES_TOPICS','android.permission.WAKE_LOCK','android.permission.FOREGROUND_SERVICE'} if ads else set()
 metadata={m.get(ANDROID+'name'):m.get(ANDROID+'value') for m in application.findall('meta-data')}
 native_plugins=['org.godotengine.plugin.v2.PoingGodotAdMob','org.godotengine.plugin.v2.PoingGodotAdMobConsentInformation','org.godotengine.plugin.v2.PoingGodotAdMobUserMessagingPlatform']
 if ads:
  if not {'android.permission.INTERNET','android.permission.ACCESS_NETWORK_STATE'}.issubset(permissions): raise SystemExit('Native ad build is missing network permissions')
  if not all(n in metadata for n in native_plugins): raise SystemExit('Native ads/UMP plugin metadata missing; variant was not actually integrated')
  if metadata.get('com.google.android.gms.ads.APPLICATION_ID')!='ca-app-pub-3940256099942544~3347511713': raise SystemExit('Only authorized Google test app ID is permitted')
 elif any(n in metadata for n in native_plugins): raise SystemExit('Offline build unexpectedly includes native ads')
 if ads:
  signature_permission='com.hexboundkingdoms.game.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
  declarations=[p for p in root.findall('permission') if p.get(ANDROID+'name')==signature_permission]
  if len(declarations)==1 and declarations[0].get(ANDROID+'protectionLevel') in ['signature','0x00000002']:
   allowed.add(signature_permission)
  if 'android.permission.READ_BASIC_PHONE_STATE' in permissions: raise SystemExit('Optional phone-state permission must be removed')
 unexpected=set(permissions)-allowed
 if unexpected: raise SystemExit('Unexpected permissions require investigation: '+str(sorted(unexpected)))
 report={'package':root.attrib['package'],'min_sdk':26,'target_sdk':36,'allow_backup':False,'debuggable':False,'permissions':permissions,'test_ads':ads,'native_ad_plugins_present':all(n in metadata for n in native_plugins),'bundletool_validation':'passed','device_validation':'unrun'}
 Path('build/manifest-audit.json').write_text(json.dumps(report,indent=2))
 print(json.dumps(report,indent=2))
if __name__=='__main__': main(sys.argv[1])
