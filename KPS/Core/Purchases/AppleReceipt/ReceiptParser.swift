//
//  ReceiptParser.swift
//  KPS
//
//  Created by mingshing on 2022/3/18.
//

import Foundation

class ReceiptParser {

    private let objectIdentifierBuilder: ASN1ObjectIdentifierBuilder
    private let containerBuilder: ASN1ContainerBuilder
    private let receiptBuilder: AppleReceiptBuilder

    init(objectIdentifierBuilder: ASN1ObjectIdentifierBuilder = ASN1ObjectIdentifierBuilder(),
         containerBuilder: ASN1ContainerBuilder = ASN1ContainerBuilder(),
         receiptBuilder: AppleReceiptBuilder = AppleReceiptBuilder()) {
        self.objectIdentifierBuilder = objectIdentifierBuilder
        self.containerBuilder = containerBuilder
        self.receiptBuilder = receiptBuilder
    }

    func receiptHasTransactions(receiptData: Data) -> Bool {
        
        if let receipt = try? parse(from: receiptData) {
            return receipt.inAppPurchases.count > 0
        }
        return true
    }

    func parse(from receiptData: Data) throws -> AppleReceipt {
        let intData = [UInt8](receiptData)

        let asn1Container = try containerBuilder.build(fromPayload: ArraySlice(intData))
        guard let receiptASN1Container = try findASN1Container(withObjectId: ASN1ObjectIdentifier.data,
                                                               inContainer: asn1Container) else {
         
            throw ReceiptReadingError.dataObjectIdentifierMissing
        }
        let receipt = try receiptBuilder.build(fromContainer: receiptASN1Container)
        
        return receipt
    }
}

private extension ReceiptParser {

    func findASN1Container(withObjectId objectId: ASN1ObjectIdentifier,
                           inContainer container: ASN1Container) throws -> ASN1Container? {
        if container.encodingType == .constructed {
            for (index, internalContainer) in container.internalContainers.enumerated() {
                if internalContainer.containerIdentifier == .objectIdentifier {
                    let objectIdentifier = try objectIdentifierBuilder.build(
                        fromPayload: internalContainer.internalPayload)
                    if objectIdentifier == objectId && index < container.internalContainers.count - 1 {
                        // the container that holds the data comes right after the one with the object identifier
                        return container.internalContainers[index + 1]
                    }
                } else {
                    let receipt = try findASN1Container(withObjectId: objectId, inContainer: internalContainer)
                    if receipt != nil {
                        return receipt
                    }
                }
            }
        }
        return nil
    }

}
