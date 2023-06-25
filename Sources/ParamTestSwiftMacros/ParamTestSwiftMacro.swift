import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ParamTestSwiftError: Error, CustomStringConvertible {
    case message(String)
    case notFunctionDecl
    case notArrayArgument
    case noElementsInArrayArgument
    case differentTupleElementCount
    
    public var description: String {
        switch self {
        case .message(let text): text
        case .notFunctionDecl: "@ParameterizedTest only works on function declaration"
        case .notArrayArgument: "@ParameterizedTest only works with array argument"
        case .noElementsInArrayArgument: "@ParameterizedTest only works with array argument contains at least one element"
        case .differentTupleElementCount : "@ParameterizedTest only works with that the number of inputs is the same as the number of tuple's elements"
        }
    }
}

public struct ParameterizedTestMacro: PeerMacro {
    public static func expansion<Context, Declaration>(
        of node: AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] where Context: MacroExpansionContext, Declaration: DeclSyntaxProtocol {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw ParamTestSwiftError.notFunctionDecl
        }
        
        let newAttributeList = AttributeListSyntax(funcDecl.attributes?.filter(excludedNodeAttribute(node: node)) ?? [])
        let arrayArgument = try extractArrayArgument(node: node)
        let bodies = try arrayArgument.elements.map(generateBody(funcDecl: funcDecl))
        let newFuncs = zip(bodies, bodies.indices).map(generateNewFunc(newAttributeList: newAttributeList, funcDecl: funcDecl))
        
        return newFuncs
    }
    
    private static func excludedNodeAttribute(node: AttributeSyntax) -> (AttributeListSyntax.Element) -> Bool {
        switch node.attributeName.as(SimpleTypeIdentifierSyntax.self) {
        case .some(let nodeType):
            return {
                guard case let .attribute(attribute) = $0,
                      let attributeType = attribute.attributeName.as(SimpleTypeIdentifierSyntax.self)
                else { return false }
                return attributeType.name.text != nodeType.name.text
            }
        case .none:
            return { _ in false }
        }
    }
    
    private static func extractArrayArgument(node: AttributeSyntax) throws -> ArrayExprSyntax {
        guard case let .argumentList(arguments) = node.argument,
              let firstElement = arguments.first,
              let arrayLiteral = firstElement.expression.as(ArrayExprSyntax.self)
        else {
            throw ParamTestSwiftError.notArrayArgument
        }
        
        guard !arrayLiteral.elements.isEmpty else {
            throw ParamTestSwiftError.noElementsInArrayArgument
        }
        
        return arrayLiteral
    }
    
    private static func generateBody(
        funcDecl: FunctionDeclSyntax) throws -> (ArrayElementListSyntax.Element) throws -> String {
            { element in
                if element.expression.is(TupleExprSyntax.self) {
                    let numberOfInputs = funcDecl.signature.input.parameterList.count
                    let elementList = element.expression.cast(TupleExprSyntax.self).elementList
                    guard elementList.count == numberOfInputs else {
                        throw ParamTestSwiftError.differentTupleElementCount
                    }
                    return zip(elementList, funcDecl.signature.input.parameterList
                    ).reduce("") { result, next in
                        result + "let \(next.1.firstName.text): \(next.1.type) = \(next.0.firstToken(viewMode: .sourceAccurate)!.text)\n"
                    }
                } else if element.expression.is(ExprSyntax.self) {
                    let firstParam = funcDecl.signature.input.parameterList.first!
                    let firstSignatureName = firstParam.firstName.text
                    return "let \(firstSignatureName): \(firstParam.type) = \(element.firstToken(viewMode: .sourceAccurate)!.text)"
                } else {
                    return ""
                }
            }
        }
    
    private static func generateNewFunc(newAttributeList: AttributeListSyntax,
                                        funcDecl: FunctionDeclSyntax) -> (String, Int) -> DeclSyntax {
        { body, index in
          DeclSyntax(
                FunctionDeclSyntax(
                    leadingTrivia: .newlines(2),
                    attributes: newAttributeList,
                    modifiers: funcDecl.modifiers,
                    funcKeyword: funcDecl.funcKeyword,
                    identifier: generateNewIdentifier(funcDecl: funcDecl, index: index),
                    genericParameterClause: funcDecl.genericParameterClause,
                    signature: funcDecl.signature
                        .with(\.input,
                               funcDecl.signature.input.with(\.parameterList, FunctionParameterListSyntax([])))
                        .with(\.output, nil),
                    genericWhereClause: nil,
                    body: CodeBlockSyntax(
                        leftBrace: .leftBraceToken(leadingTrivia: .space),
                        statements: CodeBlockItemListSyntax([
                            CodeBlockItemSyntax(item: .expr("\(raw: body)"))
                        ] + funcDecl.body!.statements.map { element in element.with(\.leadingTrivia, []) }),
                        rightBrace: .rightBraceToken(leadingTrivia: .newline)
                    ),
                    trailingTrivia: nil
                )
            )
        }
    }

  private static func generateNewIdentifier(funcDecl: FunctionDeclSyntax, index: Int) -> TokenSyntax {
    let firstChar = funcDecl.identifier.text.first?.uppercased() ?? ""
    let rest = funcDecl.identifier.text.dropFirst()
    let netIdentifier = TokenSyntax.identifier(firstChar + rest)
                                   .with(\.leadingTrivia, "test")
                                   .with(\.trailingTrivia, "_\(index)")
    return netIdentifier
  }
}

@main
struct ParamTestSwiftPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ParameterizedTestMacro.self,
    ]
}
