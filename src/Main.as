package
{
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.Bitmap;
	import flash.display.NativeWindow;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.InvokeEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.getTimer;
	import tool.ui.Files;
	
	/**
	 * ...
	 * @author lizhi
	 */
	public class Main extends Sprite 
	{
		[Embed(source = "skin/background.png")]private var bgc:Class;
		[Embed(source="skin/progress_fore.png")]private var pc:Class;
		private var p:Bitmap;
		private var config:Object;
		private var md5:String;
		private var url:String;
		private var exeName:String;
		private var md5File:File;
		private var exeFile:File;
		private var info:NativeProcessStartupInfo;
		public function Main() 
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, nativeApplication_invoke);
			
		}
		
		private function startExe():void{
			info.executable = exeFile;
			info.workingDirectory = md5File;
			var np:NativeProcess = new NativeProcess;
			np.start(info);
			NativeApplication.nativeApplication.exit();
		}
		
		private function reLoad():void{
			trace("reload");
			var loader:URLLoader = new URLLoader;
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, loader_complete);
			loader.addEventListener(ProgressEvent.PROGRESS, loader_progress);
			loader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioError);
			loader.load(new URLRequest(url));
		}
		
		private function loader_progress(e:ProgressEvent):void 
		{
			
			p.scrollRect = new Rectangle(0, 0, e.bytesLoaded/e.bytesTotal * p.bitmapData.width, p.bitmapData.height);
		}
		
		private function loader_ioError(e:IOErrorEvent):void 
		{
			reLoad();
		}
		
		private function loader_complete(e:Event):void 
		{
			var airfile:File = new File(File.applicationDirectory.resolvePath("Adobe AIR").nativePath);
			if (airfile.exists){
				airfile.copyTo(md5File.resolvePath("Adobe AIR"), true);
			}
			var zip:FZip = new FZip;
			zip.loadBytes((e.currentTarget as URLLoader).data);
			for (var i:int = 0; i < zip.getFileCount();i++ ){
				var ffile:FZipFile = zip.getFileAt(i);
				trace("---------------"+ffile.filename);
				if (ffile.filename.charAt(ffile.filename.length - 1) != "/"){
					var file:File = md5File.resolvePath(ffile.filename);
					Files.writeByte(file, ffile.content);
				}
			}
			startExe();
		}
		
		private function nativeApplication_invoke(e:InvokeEvent):void 
		{
			var is64:Boolean = Capabilities.supports64BitProcesses;
			config=JSON.parse(Files.readString(File.applicationDirectory.resolvePath("config.json")));
			md5 = is64?config.md5:config.x86md5;
			url = is64?config.url:config.x86url;
			exeName = config.exeName;
			
			md5File =new File(File.applicationDirectory.resolvePath(md5).nativePath);
			exeFile = md5File.resolvePath(exeName);
			
			//trace("1", e.arguments);
			info = new NativeProcessStartupInfo;
			info.arguments = Vector.<String>(e.arguments);
			
			if (exeFile.exists){
				startExe();
			}else{
				
				var bg:Bitmap = new bgc as Bitmap;
				addChild(bg);
				
				p = new pc as Bitmap;
				addChild(p);
				p.width = 200;
				p.x = 60;
				p.y = 140;
				p.scrollRect = new Rectangle(0, 0, 0, 0);
				var w:NativeWindow=NativeApplication.nativeApplication.openedWindows[0];
				w.stage.align = StageAlign.TOP_LEFT;
				w.stage.scaleMode = StageScaleMode.NO_SCALE;
				w.width = bg.width;
				w.height = bg.height;
				w.x = w.stage.fullScreenWidth / 2 - bg.width / 2;
				w.y = w.stage.fullScreenHeight / 2 - bg.height / 2;
				
				//下载
				if (md5File.exists){
					md5File.deleteDirectory(true);
				}
				reLoad();
			}
			
			//判断cpu型号
			//读配置
			//判断本地存在md5文件夹
			//如果不存在，重新下载
			
			//下载完成后，存储目录，复制air环境,执行
			//存在执行
			
			
		}
		
	}
	
}