-- Indexes on REF columns for joins/relationships
CREATE INDEX IdxProdBatchProduct ON ProductBatch(BatchProduct);
CREATE INDEX IdxLogTeamChief ON LogisticTeam(TeamChief);
CREATE INDEX IdxBatchOrderByCustomer ON BatchOrder(ByCustomer);
CREATE INDEX IdxBatchOrderByLogTeam ON BatchOrder(ByLogisticTeam);
CREATE INDEX IdxComplaintByCustomer ON Complaint(ByCustomer);
CREATE INDEX IdxComplaintOnBatchOrder ON Complaint(OnBatchOrder);

-- Indexes for frequently queried columns
CREATE INDEX IdxProductCategory ON Product(ProductCategory);
CREATE INDEX IdxProductExpiryDate ON Product(ExpiryDate);
CREATE INDEX IdxBatchOrderDeliveryStatus ON BatchOrder(DeliveryStatus);
CREATE INDEX IdxComplaintType ON Complaint(ComplaintType);
