import Cocoa
import AutomatticTracks

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DDLog.add(DDASLLogger())
        DDLog.add(DDTTYLogger())
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
