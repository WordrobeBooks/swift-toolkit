//
//  MediaOverlays.swift
//  R2Streamer
//
//  Created by Alexandre Camilleri on 4/11/17.
//  Copyright © 2017 Readium. All rights reserved.
//

import Foundation

public enum MediaOverlaysError: Error {
    case nodeNotFound(forFragmentId: String?)
}

// The functionnal wrapper around mediaOverlayNodes.

/// The object representing the MediaOverlays for a Link.
/// Two ways of using it, using the `Clip`s or `MediaOverlayNode`s.
/// Clips or a functionnal representation of a `MediaOverlayNode` (while the
/// MediaOverlayNode is more of an XML->Object representation.
public class MediaOverlays {
    public var nodes: [MediaOverlayNode]!

    init(withNodes nodes: [MediaOverlayNode] = [MediaOverlayNode]()) {
        self.nodes = nodes
    }
    
    internal func append(_ newNode: MediaOverlayNode) {
        nodes.append(newNode)
    }

    /// Get the audio `Clip` associated to an audio Fragment id.
    /// The fragment id can be found in the HTML document in <p> & <span> tags,
    /// it refer to a element of one of the SMIL files, providing informations
    /// about the synchronized audio.
    /// This function returns the clip representing this element from SMIL.
    ///
    /// - Parameter id: The audio fragment id.
    /// - Returns: The `Clip`, representation of the associated SMIL element.
    /// - Throws: `MediaOverlayNodeError.audio`,
    ///           `MediaOverlayNodeError.timersParsing`.
    public func clip(forFragmentId id: String) throws -> Clip {
        let clip: Clip

        do {
            let fragmentNode = try node(forFragmentId: id)

            clip = try fragmentNode.clip()
        }
        return clip
    }

    /// Get the audio `Clip` for the node right after the one designated by
    /// `id`.
    /// The fragment id can be found in the HTML document in <p> & <span> tags,
    /// it refer to a element of one of the SMIL files, providing informations
    /// about the synchronized audio.
    /// This function returns the `Clip representing the element following this
    /// element from SMIL.
    ///
    /// - Parameter id: The audio fragment id.
    /// - Returns: The `Clip` for the node element positioned right after the
    ///            one designated by `id`.
    /// - Throws: `MediaOverlayNodeError.audio`,
    ///           `MediaOverlayNodeError.timersParsing`.
    public func clip(nextAfterFragmentId id: String) throws -> Clip {
        let clip: Clip

        do {
            let fragmentNextNode = try node(nextAfterFragmentId: id)
            clip = try fragmentNextNode.clip()
        }
        return clip
    }

    /// Return the `MediaOverlayNode` found for the given 'fragment id'.
    ///
    /// - Parameter forFragment: The SMIL fragment identifier.
    /// - Returns: The node associated to the fragment.
    public func node(forFragmentId id: String?) throws -> MediaOverlayNode {
        guard let node = _findNode(forFragment: id, inNodes: self.nodes) else {
            throw MediaOverlaysError.nodeNotFound(forFragmentId: id)
        }
        return node
    }

    /// Return the `MediaOverlayNode` right after the node found for the given
    /// 'fragment id'.
    ///
    /// - Parameter forFragment: The SMIL fragment identifier.
    /// - Returns: The node right after the node associated to the fragment.
    public func node(nextAfterFragmentId id: String?) throws -> MediaOverlayNode {
        guard let node = _findNextNode(forFragment: id, inNodes: self.nodes) else {
            throw MediaOverlaysError.nodeNotFound(forFragmentId: id)
        }
        return node
    }

    // Mark: - Fileprivate Methods.

    /// [RECURISVE]
    /// Find the node (<par>) corresponding to "fragment" ?? nil.
    ///
    /// - Parameters:
    ///   - fragment: The current fragment name for which we are looking the
    ///               associated media overlay node.
    ///   - nodes: The set of MediaOverlayNodes where to search. Default to
    ///            self children.
    /// - Returns: The node we found ?? nil.
    fileprivate func _findNode(forFragment fragment: String?,
                               inNodes nodes: [MediaOverlayNode]) -> MediaOverlayNode?
    {
        // For each node of the current scope..
        for node in nodes {
            // If the node is a "section" (<seq> sequence element)..
            // FIXME: ask if really usefull?
            if node.role.contains("section") {
                // Try to find par nodes inside.
                if let found = _findNode(forFragment: fragment, inNodes: node.children)
                {
                    return found
                }
            }
            // If the node text refer to filename or that filename is nil,
            // return node.
            if fragment == nil || node.text?.contains(fragment!) ?? false {
                return node
            }
        }
        // If nothing found, return nil.
        return nil
    }

    /// [RECURISVE]
    /// Find the node (<par>) corresponding to the next one after the given
    /// "fragment" ?? nil.
    ///
    /// - Parameters:
    ///   - fragment: The fragment name corresponding to the node previous to
    ///               the one we want.
    ///   - nodes: The set of MediaOverlayNodes where to search. Default to
    ///            self children.
    /// - Returns: The node we found ?? nil.
    fileprivate func _findNextNode(forFragment fragment: String?,
                                   inNodes nodes: [MediaOverlayNode]) -> MediaOverlayNode?
    {
        var previousNodeFoundFlag = false

        // For each node of the current scope..
        for node in nodes {
            guard !previousNodeFoundFlag else {
                return node
            }
            // If the node is a "section" (<seq> sequence element)..
            if node.role.contains("section") {
                if let found = _findNextNode(forFragment: fragment, inNodes: node.children) {
                    return found
                }
            }
            // If the node text refer to filename or that filename is nil,
            // return node.
            if fragment == nil || node.text?.contains(fragment!)  ?? false {
                previousNodeFoundFlag = true
            }
        }
        // If nothing found, return nil.
        return nil
    }
}
