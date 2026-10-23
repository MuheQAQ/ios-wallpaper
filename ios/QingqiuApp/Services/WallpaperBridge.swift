import Darwin
import UIKit

@_silgen_name("notify_post")
private func qq_notify_post(_ name: UnsafePointer<CChar>) -> UInt32

struct WallpaperBridge {
    func send(imageData: Data) throws {
        guard UIImage(data: imageData) != nil else { throw BridgeError.invalidImage }
        let pasteboard = UIPasteboard(name: UIPasteboard.Name(WallpaperProtocol.requestPasteboardName), create: true)
        pasteboard?.setData(imageData, forPasteboardType: "public.data")
        guard pasteboard?.data(forPasteboardType: "public.data") != nil else { throw BridgeError.past}ÒÚ$z{-®éÜj×7FV&ö&BÒT•7FV&ö&B†æÖS¢T•7FV&ö&BäæÖR…vÆÇW%&÷Fö6öÂç&W7VÇE7FV&ö&DæÖR’Â7&VFS¢fÇ6R¢wV&BÆWBFFÒ7FV&ö&CòæFF†f÷%7FV&ö&EG—S¢'V&Æ–2æ§6öâ"’VÇ6R²&WGW&âæ–ÂÐ¢&WGW&âG'“ò¥4ôäFV6öFW"‚’æFV6öFR…vÆÇW%6WE&W7VÇBç6VÆbÂg&öÓ¢FF¢Ð ¢VçVÒ'&–FvTW'&÷#¢Æö6Æ—¦VDW'&÷"°¢66R–çfÆ–D–ÖvRÂ7FV&ö&EVæf–Æ&ÆRÂæ÷F–f–6F–öäf–ÆVB„–çC3"¢f"W'&÷$FW67&—F–öã¢7G&–æsò°¢7v—F6‚6VÆb°¢66Ræ–çfÆ–D–ÖvS¢&WGW&â.Kˆ¾‹ÛÞXh^ZëžKˆÞiŠþXúþŠz>zY»îx˜r ¢66Rç7FV&ö&EVæf–Æ&ÆS¢&WGW&â.izk9^Y	Z8{«Žhù.K»nKÊ˜	.Y»îx˜r ¢66Rææ÷F–f–6F–öäf–ÆVB†ÆWB6öFR“¢&WGW&â.Z8{«Žhù.K»n˜	®yú^ZK‹JR…Â†6öFR’’ ¢Ð¢Ð¢Ð§Ð