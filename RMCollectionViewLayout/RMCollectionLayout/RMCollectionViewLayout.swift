//
//  RMCollectionViewLayout.swift
//  RMCollectionViewLayout
//
//  Created by 迟浩东 on 2017/4/6.
//  Copyright © 2017年 迟浩东. All rights reserved.
//


import UIKit

@objc protocol RMCollectionViewLayoutDelegate : NSObjectProtocol {
    
    /** 根据宽度，获取对应的比例的高度 用于垂直滚动 */
    func collectionViewLayout(_ collectionViewLayout: RMCollectionViewLayout, heightForItemAt index: Int, itemWidth width:CGFloat) -> CGFloat
    
    /** 根据高度，获取对应的比例的宽度 用于水平滚动 */
    func collectionViewLayout(_ collectionViewLayout: RMCollectionViewLayout, widthForItemAt index: Int, itemHeight height:CGFloat) -> CGFloat
    
    
    /** 获取列数 只针对垂直滚动有效 */
    @objc optional func columnCountInLayout(_ collectionViewLayout: RMCollectionViewLayout) -> NSInteger
    /** 获取行数 只针对水平滚动有效 */
    @objc optional func rowCountInLayout(_ collectionViewLayout: RMCollectionViewLayout) -> NSInteger
    /** 列间距 */
    @objc optional func columnMarginInLayout(_ collectionViewLayout: RMCollectionViewLayout) -> CGFloat
    /** 行间距 */
    @objc optional func rowMarginInLayout(_ collectionViewLayout: RMCollectionViewLayout) -> CGFloat
    /** 上左下右间距 */
    @objc optional func edgeInsetsInLayout(_ collectionViewLayout: RMCollectionViewLayout) -> UIEdgeInsets
}
/** 滚动方向 */
enum ScrollDirection: Int {
    case horizontal = 0
    case vertical   = 1
}

/// 头部Header 标识
let kSupplementaryViewKindHeader = "kSupplementaryViewKindHeader"

class RMCollectionViewLayout: UICollectionViewLayout {
    
    /** 默认header高度 */
    var defaultHeaderHeight: CGFloat = 40.0
    /** 是否有Header，默认为false（没有）, 与defaultHeaderHeight结合使用 */
    var isLoadHeader = false
    /** 头部的HeaderView是否随着滚动固定顶部 */
    private var isFollowScroll: Bool {return true}
    
    
    /** 列数 用于垂直滚动*/
    var defaultColumnCount = 2
    /** 行数 用于水平滚动*/
    var defaultRowCount = 2
    /** 列间距 */
    var defaultColumnMargin = 10.0
    /** 行间距 */
    var defaultRowMargin = 10.0
    /** 上左下右间距 */
    var defaultEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    /** 存放位置的数组 */
    private var attributes: [UICollectionViewLayoutAttributes] = []
    /** 内容高度 用于垂直滚动 */
    private var contentHeight: CGFloat = 0.0
    /** 内容宽度 用于水平滚动*/
    private var contentWidth: CGFloat = 0.0
    /** 存放高度数组 用于垂直滚动 */
    private var columnHeights = [CGFloat]()
    /** 存放宽度数组 用于水平滚动 */
    private var rowWidths = [CGFloat]()
    /** 滚动方向 默认垂直 */
    var scrollDirection: ScrollDirection = .vertical
    
    // 代理
    weak var delegate: RMCollectionViewLayoutDelegate!
    
    // 重写父类方法
    override func prepare() {
        super.prepare()
        
        // 每次都清空计算的高度
        columnHeights .removeAll()
        rowWidths.removeAll()
        // 初始化高度数组
        for _ in 0..<columnCount() {
            columnHeights.append(edgeInsets().top)
        }
        for _ in 0..<rowCount() {
            rowWidths.append(edgeInsets().left)
        }
        // 每次都清空所有位置
        attributes.removeAll()
        
        let itemCount = self.collectionView!.numberOfItems(inSection: 0)
        
        for i in 0..<itemCount {
            let indexPath = IndexPath(item: i, section: 0)
            let attr = layoutAttributesForItem(at: indexPath)
            
            attributes.append(attr!)
        }
    }
    // 返回位置数组
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if isLoadHeader {
            /** 添加一个头部 */
            let indexPath = IndexPath(item: 0, section: 0)
            let attr = self.layoutAttributesForSupplementaryView(ofKind: kSupplementaryViewKindHeader, at: indexPath)
            attributes.append(attr!)
        }
        return attributes
    }
    // 内容总高度、宽度
    override var collectionViewContentSize: CGSize {
        return collectinViewScrollDirection() ? CGSize(width: 0, height: contentHeight + edgeInsets().bottom) : CGSize(width: contentWidth + edgeInsets().right, height: 0)
    }
    // 计算每个item位置
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        // 获取CollectionView宽高
        let collectionViewW = collectionView?.frame.size.width
        let collectionViewH = collectionView?.frame.size.height
        // 垂直滚动，宽度一样
        let defaultW = (collectionViewW! - edgeInsets().left - edgeInsets().right - CGFloat(columnCount() - 1) * columnMargin()) / CGFloat(columnCount())
        // 水平滚动，高度一样
        let defaultH = (collectionViewH! - edgeInsets().top - edgeInsets().bottom - CGFloat(rowCount() - 1) * rowMargin()) / CGFloat(rowCount())
        
        let w = collectinViewScrollDirection() ? defaultW : delegate.collectionViewLayout(self, widthForItemAt: indexPath.item, itemHeight: defaultH)
        let h = collectinViewScrollDirection() ? delegate.collectionViewLayout(self, heightForItemAt: indexPath.item, itemWidth: defaultW) : defaultH
        
        // 找到高度最短的列/行
        var minColumnOrRow = 0
        // 获取第一列高度/宽度
        var minColumnHeightOrWidth = collectinViewScrollDirection() ? columnHeights[0] : rowWidths[0]
        for i in 1..<(collectinViewScrollDirection() ? columnCount() : rowCount()) {
            let columnHeightOrWidth = collectinViewScrollDirection() ? columnHeights[i] : rowWidths[i]
            if minColumnHeightOrWidth > columnHeightOrWidth {
                minColumnHeightOrWidth = columnHeightOrWidth
                minColumnOrRow = i
            }
        }
        
        // 计算 x y 位置
        var x = collectinViewScrollDirection() ? edgeInsets().left + (CGFloat(minColumnOrRow) * (w + columnMargin())) : minColumnHeightOrWidth
//        var y = collectinViewScrollDirection() ? minColumnHeightOrWidth : edgeInsets().top + (CGFloat(minColumnOrRow) * (h + rowMargin()))
        var y = collectinViewScrollDirection() ? minColumnHeightOrWidth == edgeInsets().top && isLoadHeader ? defaultHeaderHeight : minColumnHeightOrWidth : edgeInsets().top + (CGFloat(minColumnOrRow) * (h + rowMargin()))
        
        if y != edgeInsets().top && collectinViewScrollDirection(){
            y += rowMargin()
        } else if x != edgeInsets().left && !collectinViewScrollDirection() {
            x += columnMargin()
        }
        // print("宽度：\(w)，高度：\(h)")
        // 设置位置
        attr.frame = CGRect(x: Double(x), y: Double(y), width: Double(w), height: Double(h))
        
        if collectinViewScrollDirection() {
            // 更新最短列的高度 垂直滚动
            columnHeights[minColumnOrRow] = attr.frame.maxY
            // 获取内容高度
            let columnHeihgt =  columnHeights[minColumnOrRow]
            if self.contentHeight < columnHeihgt {
                self.contentHeight = columnHeihgt
            }
        } else {
            // 更新最短行的宽度 水平滚动
            rowWidths[minColumnOrRow] = attr.frame.maxX
            // 获取内容宽度
            let rowWidth =  rowWidths[minColumnOrRow]
            if self.contentWidth < rowWidth {
                self.contentWidth = rowWidth
            }
        }
        
        
        
        return attr
    }
    
    // 头部Header设置,暂时只支持一组
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        
        if elementKind == kSupplementaryViewKindHeader {
            
            let width = self.collectionView?.bounds.size.width
            let height: CGFloat = defaultHeaderHeight
            
            let offsetY = self.collectionView!.contentOffset.y
            let y =  isFollowScroll ? 0 : max(0,offsetY)
            attributes.frame = CGRect(x: 0, y: y, width: width!, height: height)
        }
        
        return attributes
    }
    
    /** 判断滚动方向 */
    private func collectinViewScrollDirection() -> Bool {
        if scrollDirection == .vertical { // 垂直滚动
            return true
        } else { // 水平滚动
            return false
        }
    }
    
    /** 代理获取行数 水平滚动 */
    private func rowCount() -> NSInteger {
        
        guard let rowCount = delegate.rowCountInLayout?(self) else {
            return defaultRowCount
        }
        return rowCount
        
        /**
         * 这个写法同上面效果一样，但是推荐上面Swift写法
        if delegate.responds(to: #selector(RMCollectionViewLayoutDelegate.rowCountInLayout(_:))) {
            return delegate.rowCountInLayout!(self)
        } else {
            return defaultRowCount
        }
        */
    }
    /** 代理获取列数 垂直滚动 */
    private func columnCount() -> NSInteger {
        
        guard let columnCount = delegate.columnCountInLayout?(self) else {
            return defaultColumnCount
        }
        return columnCount
        
        /**
        if delegate.responds(to: #selector(RMCollectionViewLayoutDelegate.columnCountInLayout(_:))) {
            return delegate.columnCountInLayout!(self)
        } else {
            return defaultColumnCount
        }
        */
    }
    /** 代理获取列间距 */
    private func columnMargin() -> CGFloat {
        
        guard let columnMargin = delegate.columnMarginInLayout?(self) else {
            return CGFloat(defaultColumnMargin)
        }
        return columnMargin
        
        /**
        if delegate.responds(to: #selector(RMCollectionViewLayoutDelegate.columnMarginInLayout(_:))) {
            return delegate.columnMarginInLayout!(self)
        } else {
            return CGFloat(defaultColumnMargin)
        }
        */
    }
    /** 代理获取行间距 */
    private func rowMargin() -> CGFloat {
        
        guard let rowMargin = delegate.rowMarginInLayout?(self) else {
            return CGFloat(defaultRowMargin)
        }
        return rowMargin
        
        /**
        if delegate.responds(to: #selector(RMCollectionViewLayoutDelegate.rowMarginInLayout(_:))) {
            return delegate.rowMarginInLayout!(self)
        } else {
            return CGFloat(defaultRowMargin)
        }
        */
    }
    /** 代理获取上左下右间距 */
    private func edgeInsets() -> UIEdgeInsets {
        
        guard let edgeInsets = delegate.edgeInsetsInLayout?(self) else {
            return defaultEdgeInsets
        }
        return edgeInsets
        
        /**
        if delegate.responds(to: #selector(RMCollectionViewLayoutDelegate.edgeInsetsInLayout(_:))) {
            return delegate.edgeInsetsInLayout!(self)
        } else {
            return defaultEdgeInsets
        }
        */
    }
}

