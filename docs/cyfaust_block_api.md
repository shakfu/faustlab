

## Example 1

original cpp

```c++
Box box = boxPar(boxInt(7), boxReal(3.14));
```

python equivalent

```python
box = box_par(box_int(7), box_real(3.14))
```

python oo

```python
box = Box(7).par(Box(3.14))
```

python hybrid

```python
box = box_par(Box(7), Box(3.14))
```

## Example 2

```c++
Box box = boxSeq(boxPar(boxWire(), boxReal(3.14)), boxAdd());
```

python equivalent

```python
box = box_seq(box_par(box_wire(), box_real(3.14)), box_add_op())
```

python oo

```python
box = Box().par(Box(3.14)).seq(box_add_op())
```

python hybrid

```python
box = box_seq(Box().par(Box(3.14)), box_add_op())
```


