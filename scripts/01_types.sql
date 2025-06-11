DROP TABLE DistributionCenter;
DROP TABLE Product;
DROP TABLE ProductBatch;
DROP TABLE BatchOrder;
DROP TABLE Customer;
DROP TABLE Department;
DROP TABLE LogisticTeam;
DROP TABLE ChiefOfficier;
DROP TABLE TeamMember;
DROP TABLE Complaint;
/

DROP TYPE Location FORCE;
DROP TYPE PhoneList FORCE;
DROP TYPE ContactInfo FORCE;
DROP TYPE PreferencesList FORCE;
DROP TYPE DepartmentList FORCE;
DROP TYPE MemberList FORCE;
DROP TYPE ProductList FORCE;
DROP TYPE BatchList FORCE;
DROP TYPE DistCenter_t FORCE;
DROP TYPE Product_t FORCE;
DROP TYPE ProdBatch_t FORCE;
DROP TYPE BatchOrder_t FORCE;
DROP TYPE Customer_t FORCE;
DROP TYPE Department_t FORCE;
DROP TYPE LogisticTeam_t FORCE;
DROP TYPE ChiefOfficier_t FORCE;
DROP TYPE TeamMember_t FORCE;
DROP TYPE Complaint_t FORCE;
/

CREATE OR REPLACE TYPE Location AS OBJECT
(
    City VARCHAR2(30),
    Street VARCHAR2(30),
    StreetNo VARCHAR2(5),
    ZipCode NUMBER(5)
);
/

CREATE OR REPLACE TYPE Product_t AS OBJECT
(
    SerialNo NUMBER,
    ProductCategory VARCHAR2(30),
    ExpiryDate DATE
);
/

CREATE OR REPLACE TYPE PhoneList AS VARRAY(3) OF NUMBER(10);
/

CREATE OR REPLACE TYPE ContactInfo AS OBJECT
(
    PhoneNumbers PhoneList,
    Email VARCHAR2(50),
    Fax VARCHAR2(20)
);
/

CREATE OR REPLACE TYPE PreferencesList AS TABLE OF REF Product_t;
/

CREATE OR REPLACE TYPE Department_t AS OBJECT
(
    DepartmentID NUMBER,
    DeptContact ContactInfo,
    SupplyPreferences PreferencesList
);
/

CREATE OR REPLACE TYPE DepartmentList AS TABLE OF REF Department_t;
/

CREATE OR REPLACE TYPE Customer_t AS OBJECT
(
    CustomerCode VARCHAR2(10),
    CustomerLocation Location,
    BelongsToDepts DepartmentList
);
/

CREATE OR REPLACE TYPE TeamMember_t AS OBJECT
(
    TaxCode NUMBER,
    MemberName VARCHAR2(25),
    MemberSurname VARCHAR2(25),
    BirthDate DATE,
    EmploymentDate DATE
) NOT FINAL;
/

CREATE OR REPLACE TYPE ChiefOfficier_t UNDER TeamMember_t
(
    StartDate DATE
);
/

CREATE OR REPLACE TYPE MemberList AS TABLE OF REF TeamMember_t;
/

CREATE OR REPLACE TYPE LogisticTeam_t AS OBJECT
(
    TeamCode NUMBER,
    TeamName VARCHAR2(20),
    TeamChief REF ChiefOfficier_t,
    TeamMembers MemberList,
    CompletedDeliveries NUMBER
);
/

CREATE OR REPLACE TYPE ProductList AS TABLE OF REF Product_t;
/

CREATE OR REPLACE TYPE DistCenter_t AS OBJECT
(
    CenterName VARCHAR2(30),
    CenterLocation Location,
    ByTeam REF LogisticTeam_t,
    ListOfProducts ProductList
);
/

CREATE OR REPLACE TYPE ProdBatch_t AS OBJECT
(
    BatchID NUMBER,
    BatchProduct REF Product_t,
    Quantity NUMBER,
    ArrivalDate DATE,
    ByDistCenter REF DistCenter_t
);
/

CREATE OR REPLACE TYPE BatchList AS TABLE OF REF ProdBatch_t;
/

CREATE OR REPLACE TYPE BatchOrder_t AS OBJECT
(
    OrderID NUMBER,
    OrderBatches BatchList,
    OrderDate DATE,
    ExpectedDeliveryDate DATE,
    DeliveryStatus VARCHAR2(15),
    ByCustomer REF Customer_t,
    ByLogisticTeam REF LogisticTeam_t
);
/

CREATE OR REPLACE TYPE Complaint_t AS OBJECT
(
    TicketID NUMBER,
    ByCustomer REF Customer_t,
    OnBatchOrder REF BatchOrder_t,
    ComplaintType VARCHAR2(20),
    StartDate DATE,
    EndDate DATE
);
/