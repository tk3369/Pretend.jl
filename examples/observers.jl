# An observer pattern example
# See a similar example at https://easymock.org/getting-started.html

using Pretend
Pretend.activate()

using BinaryTraits
using BinaryTraits.Prefix: Can

using Test

# Formal interface
@trait HandleNewDocument
@implement Can{HandleNewDocument} by document_added(_, document)

# A ProofReader can handle any new documents
struct ProofReader end
document_added(reader::ProofReader, document) = println("notified document_added => $document")

# We will claim that it satisfies the HandleNewDocument trait
@assign ProofReader with Can{HandleNewDocument}
@check ProofReader

# A DocumentManager deals with all documentation needs
struct DocumentManager
    listeners::Vector
end

# Add a new document to the system
# 1. persist the document
# 2. notify any collaborator that might be interested about this event
function add(dm::DocumentManager, title, content)
    println("added doc '$title' with content '$content'")
    foreach(x -> document_added(x, title), dm.listeners)
end

reader = ProofReader()
dm = DocumentManager([reader])

# just a check
add(dm, "Life is boring", "Really? I don't think so.")

# Annotate the mockable function
@mockable document_added(reader::ProofReader, document) = println("notified document_added => $document")

# Create a mock(patch)
apply(document_added => (reader::ProofReader, document) -> println("mocked! ha!")) do
    add(dm, "Life is boring", "Really? I don't think so.")
    @test called_exactly_once(document_added, reader, "Life is boring")
end

