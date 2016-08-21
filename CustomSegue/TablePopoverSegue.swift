//
//  TablePopoverSegue.swift
//  CustomSegue
/*
 The MIT License (MIT)
 Copyright (c) 2016 Eric Marchand (phimage)
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import AppKit

// show popover near selected table view raw
public class TablePopoverSegue: NSStoryboardSegue {
    
    public weak var tableView: NSTableView?
    public var preferredEdge: NSRectEdge = NSRectEdge.MaxX
    public var popoverBehavior: NSPopoverBehavior = .Transient
    
    public override func perform() {
        guard let fromController = self.sourceController as? NSViewController,
        let toController = self.destinationController as? NSViewController,
            let tableView = self.tableView
            else { return }

        let selectedColumn = tableView.selectedColumn
        let selectedRow = tableView.selectedRow
        var selectedView = tableView as NSView
        if (selectedRow >= 0) {
            if let view = tableView.viewAtColumn(selectedColumn, row: selectedRow, makeIfNecessary: false) {
                selectedView = view
            }
        }
        fromController.presentViewController(toController, asPopoverRelativeToRect: selectedView.bounds, ofView: selectedView, preferredEdge: preferredEdge, behavior: popoverBehavior)
    }
    
}