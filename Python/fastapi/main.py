from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal, engine, Base
from models import Student
from pydantic import BaseModel

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Student Management API")

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic model for request validation
class StudentCreate(BaseModel):
    roll_number: int
    name: str
    student_class: str
    city: str

class StudentResponse(BaseModel):
    roll_number: int
    name: str
    student_class: str
    city: str

    class Config:
        orm_mode = True

@app.post("/students/", response_model=StudentResponse)
def create_student(student: StudentCreate, db: Session = Depends(get_db)):
    # Check if student already exists
    existing = db.query(Student).filter(Student.roll_number == student.roll_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="Roll number already exists")

    new_student = Student(
        roll_number=student.roll_number,
        name=student.name,
        student_class=student.student_class,
        city=student.city
    )
    db.add(new_student)
    db.commit()
    db.refresh(new_student)
    return new_student

@app.get("/students/{roll_number}", response_model=StudentResponse)
def get_student(roll_number: int, db: Session = Depends(get_db)):
    student = db.query(Student).filter(Student.roll_number == roll_number).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student
