import XCTest

class TestKeyChainManager: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func saveTest() -> OSStatus {
        let testString: String = "TEST"
        let status = KeyChainManager.save(key: "TEST", data: testString.data)
        return status
    }
    
    override func tearDown() {
        // Put teardown code herez. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSaveKeychain() {
        let status = saveTest()
        XCTAssertTrue(status == 0)
    }
    
    func testLoadKeychain() {
        _ = saveTest()
        XCTAssertTrue(KeyChainManager.load(key: "TEST") != nil)
        XCTAssertTrue(String(data: KeyChainManager.load(key: "TEST")!) == "TEST")
    }
    
    func testRemoveKeyChain() {
        _ = saveTest()
        KeyChainManager.delete(key: "TEST")
        XCTAssertTrue( KeyChainManager.load(key: "TEST")  == nil)
    }
    
}
