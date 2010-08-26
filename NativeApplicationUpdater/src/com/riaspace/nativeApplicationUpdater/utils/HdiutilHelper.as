package com.riaspace.nativeApplicationUpdater.utils
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	[Event(name="complete",type="flash.events.Event")]
	[Event(name="error",type="flash.events.ErrorEvent")]
	
	public class HdiutilHelper extends EventDispatcher
	{
		private var dmg:File;
		
		private var result:Function;
		
		private var error:Function;
		
		private var hdiutilProcess:NativeProcess;
		
		public var mountPoint:String;
		
		public function HdiutilHelper(dmg:File)
		{
			this.dmg = dmg;
			this.result = result;
			this.error = error;
		}
		
		public function attach():void
		{
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = new File("/usr/bin/hdiutil");
			
			var args:Vector.<String> = new Vector.<String>();
			args.push("attach", "-plist", dmg.nativePath);
			
			info.arguments = args;
			
			hdiutilProcess = new NativeProcess();
			hdiutilProcess.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, hdiutilProcess_errorHandler);
			hdiutilProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, hdiutilProcess_errorHandler);
			
			hdiutilProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, hdiutilProcess_outputHandler);
			
			hdiutilProcess.start(info);
		}

		private function hdiutilProcess_outputHandler(event:ProgressEvent):void
		{
			var plist:XML = new XML(hdiutilProcess.standardOutput.readUTFBytes(event.bytesLoaded));
			var dicts:XMLList = plist.dict.array.dict;

			// INFO: for some reason E4X didn't work
			for each(var dict:XML in dicts)
			{
				for each(var element:XML in dict.elements())
				{
					if (element.name() == "key" && element.text() == "mount-point")
					{
						mountPoint = dict.child(element.childIndex() + 1);
						dispatchEvent(new Event(Event.COMPLETE));
						break;
					}
				}
			}
		}

		private function hdiutilProcess_errorHandler(event:IOErrorEvent):void
		{
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, event.text, event.errorID));
		}
	}
}