
import ARKit
import SceneKit


extension SCNReferenceNode {
    convenience init(named resourceName: String, loadImmediately: Bool = true) {
        let url = Bundle.main.url(forResource: resourceName, withExtension: "scn")!
        self.init(url: url)!
        if loadImmediately {
            self.load()
        }
    }
}

extension SCNVector3{
    
    ///Get The Length Of Our Vector
    func length() -> Float { return sqrtf(x * x + y * y + z * z) }
    
    ///Allow Us To Subtract Two SCNVector3's
    static func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 { return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z) }
}

func roundDec(_ x: Float) -> Float {
    let y = round(x*10)/10
    return y
}
